/*------------------------------------------------------------------------------
 * File          : gamma_LUT.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 7, 2022
 * Description   : LUT implementation for mapping input to output values.
 *------------------------------------------------------------------------------*/

import pkg::*;

module gamma_LUT #()(
	input logic clk,
	input logic resetN,
	// Resets data out only w/o resetting RAM
	input logic datapath_resetN,
	// Resets RAM only w/o resetting datapath
	input logic params_resetN,
	input logic color_in_valid,
	
	// Read data path
	input logic g_en,
	input color_t color_in,
	output color_t color_out,
	output logic color_out_valid,
	
	// Read parameters
	// @SuppressProblem -type partially_unread_data -count 1 -length 1
	input PADDR raddr,
	output PDATA glut_rdata,
	
	// Write
	input logic glut_write_en_n,
	// @SuppressProblem -type partially_unread_data -count 1 -length 1
	input PADDR paddr,
	// @SuppressProblem -type partially_unread_data -count 1 -length 1
	input PDATA pdata,
	// stalling the pipe
	input datapath_ready
	
);
	color_t reg_color_out;
	color_t color_out_next;
	
	// gated for saving power
	color_t gated_color_in;
	assign gated_color_in = g_en ? color_in : 8'b0;
	
	assign color_out = reg_color_out;
	
			
	always_ff @(posedge clk or negedge resetN or negedge datapath_resetN)
	begin
		if(~resetN) begin
			reg_color_out <= 8'b0;
			color_out_valid <= 1'b0;
		end
		else if (~datapath_resetN) begin
			reg_color_out <= 8'b0;
			color_out_valid <= 1'b0;
		end
		else begin
			if(datapath_ready) begin
				if(~g_en) begin
					reg_color_out <= color_in;
					color_out_valid <= color_in_valid;
				end
				else begin
					reg_color_out <= color_out_next;
					color_out_valid <= color_in_valid;
				end
			end
		end
	end
	
	DW_ram_2r_w_s_dff #(.data_width(8), .depth(256), .rst_mode(0))
		DW_ram_2r_w_s_dff_inst (
			.clk(clk),
			.rst_n(resetN & params_resetN), 
			.cs_n(glut_write_en_n), 
			.wr_n(glut_write_en_n), 
			.rd1_addr(gated_color_in), 
			.rd2_addr(raddr[7:0]),
			.wr_addr(paddr[7:0]),
			.data_in(pdata[7:0]), 
			.data_rd1_out(color_out_next),
			// @SuppressProblem -type port_connection_extend_non_const_other -count 1 -length 1
			.data_rd2_out(glut_rdata[7:0])
		);
	

endmodule
