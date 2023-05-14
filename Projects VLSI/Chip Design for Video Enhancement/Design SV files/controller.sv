/*------------------------------------------------------------------------------
 * File          : controller.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 4, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
import pkg::*;

module controller #() (
	input logic clk,
	input logic rst_n,
	// Resets parameters registers only w/o resetting datapath
	input logic params_resetN,
	
	// Write
	input logic pvalid,
	input PDATA pdata, // WDATA  from Axi - Lite
	// @SuppressProblem -type partially_unread_data -count 1 -length 1
	input PADDR paddr, // AWADDR from Axi - Lite
	
	// Read
	input logic raddr_valid,
	// @SuppressProblem -type partially_unread_data -count 1 -length 1
	input PADDR raddr, // unused
	
	// Write response
	output PRESP cwresp,
	output logic cwresp_valid,
	
	// Read response
	output PDATA rdata,
	output PRESP crresp,
	output logic crresp_valid,
	
	// Internal
	input PDATA glut_to_read,
	output logic glut_write_en_n,
	output logic g_en,
	output cp_param_t cp_param,
	output logic c_en,
	output color_signed_t brightness_param,
	output logic b_en
);

	// Internal write registers control
	logic enables_write_en;
	logic cp_write_en;
	logic bp_write_en;
	
	// Enables register
	always_ff @(posedge clk or negedge rst_n or negedge params_resetN)
	begin
		if(~rst_n) begin
			{g_en, c_en, b_en} <= 3'b0;
		end
		else if(~params_resetN) begin
			{g_en, c_en, b_en} <= 3'b0;
		end
		else if (enables_write_en) begin
			{g_en, c_en, b_en} <= pdata[2:0];
		end
	end
	
	// Brightness parameter register
	always_ff @(posedge clk or negedge rst_n or negedge params_resetN)
	begin
		if(~rst_n) begin
			brightness_param <= 9'b0;
		end
		else if(~params_resetN) begin
			brightness_param <= 9'b0;
		end
		else if (bp_write_en) begin
			brightness_param <= pdata[8:0];
		end
	end
	
	color_t contrast_fp;
	logic cp_invalid;
	
	contrast_LUT contrast_LUT_inst (
		.clk        (clk        ),
		.resetN     (rst_n & params_resetN),
		.cp_write_en(cp_write_en),
		.pdata      (pdata      ),
		.contrast_fp(contrast_fp),
		.cp_param   (cp_param   ),
		.invalid    (cp_invalid )
	);
	

	// Parse and validate write address
	always_comb 
	begin : write_controller
		enables_write_en = 1'b0;
		glut_write_en_n = 1'b1;
		cp_write_en = 1'b0;
		bp_write_en = 1'b0;
		cwresp = SLVERR;
		cwresp_valid = 1'b0;
		
		if (pvalid) begin
			cwresp_valid = 1'b1;
			case(paddr[15:12])
				ADDR_ENABLES: begin
					enables_write_en = 1'b1;
					cwresp = OKAY;
				end
				ADDR_BRIGHTNESS: begin
					bp_write_en = 1'b1;
					cwresp = OKAY;
				end
				ADDR_CONTRAST: begin
					cp_write_en = 1'b1;
					if(~cp_invalid) begin
						cwresp = OKAY;
					end
				end
				ADDR_GAMMA_LUT: begin
					glut_write_en_n = 1'b0;
					cwresp = OKAY;				
				end
				default: begin
					// Not in address space
					cwresp = SLVERR;
				end
			endcase
		end
	end
	
	// Parse and validate read address
	always_comb 
	begin : read_controller
		// @SuppressProblem -type assign_truncation_const_value_unchanged -count 1 -length 1
		rdata = 0;
		crresp = SLVERR;
		crresp_valid = 1'b0;
		
		if (raddr_valid) begin
			crresp_valid = 1'b1;
			case(raddr[15:12])
				ADDR_ENABLES: begin
					// @SuppressProblem -type assign_extend_non_const_other -count 1 -length 1
					rdata = {g_en, c_en, b_en};
					crresp = OKAY;
				end
				ADDR_BRIGHTNESS: begin
					// @SuppressProblem -type assign_extend_non_const_other -count 1 -length 1
					rdata = brightness_param;
					crresp = OKAY;
				end
				ADDR_CONTRAST: begin
					// @SuppressProblem -type assign_extend_non_const_other -count 1 -length 1
					rdata = contrast_fp;
					crresp = OKAY;
				end
				ADDR_GAMMA_LUT: begin
					rdata = glut_to_read;
					crresp = OKAY;				
				end
				default: begin
					// Not in address space
					// @SuppressProblem -type assign_truncation_const_value_unchanged -count 1 -length 1
					rdata = 0;
					crresp = SLVERR;
				end
			endcase
		end
	end

	
endmodule