/*------------------------------------------------------------------------------
 * File          : contrast.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 2, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
import pkg::*;

module contrast #() (
	input logic clk,
	input logic resetN,
	
	input logic en_cp,
	input cp_param_t cp_param,
	input color_t color_in,
	
	input logic color_in_valid,
	output logic color_out_valid,
	
	// to stall the pipe
	input datapath_ready,
	
	output color_t color_out
);
	logic sign;
	shifted_t shifted_a;
	shifted_t shifted_b;
	
	logic signed [10:0] result;
	color_t color_out_next;
	
	assign sign = cp_param.sign;
	
	shifter shifter_a (
		.color_in(color_in),
		.shifter_param(cp_param.shifter_a), .shift_en(en_cp),
		.color_out(shifted_a)
		);
	
	shifter shifter_b (
		.color_in(color_in),
		.shifter_param(cp_param.shifter_b), .shift_en(en_cp),
		.color_out(shifted_b)
		);
	
	always_comb
	begin
		if(en_cp) begin
			if(sign == SUB) begin
				result = {1'b0, shifted_a} - {1'b0, shifted_b};
			end
			else begin
				result = {1'b0, shifted_a} + {1'b0, shifted_b};
			end
			
			if(result[10] | result[9] | result[8]) begin
				color_out_next = MAX_COLOR;
			end
			else begin
				color_out_next = result[7:0];
			end
		end
		else begin
			color_out_next = color_in;
		end
	end
	
	always_ff @(posedge clk or negedge resetN)
	begin
		if(~resetN) begin
			color_out <= MIN_COLOR;
			color_out_valid <= 1'b0;
		end
			
		else if(datapath_ready) begin
			color_out <= color_out_next;
			color_out_valid <= color_in_valid;
		end
		
	end
	
endmodule