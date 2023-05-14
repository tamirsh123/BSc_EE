/*------------------------------------------------------------------------------
 * File          : brightness.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 2, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
import pkg::*;

module brightness #() (
	input logic clk,
	input logic resetN,
	input logic en_bp,
	
	input color_signed_t brightness_param,
	input color_t color_in,
	
	input logic color_in_valid,
	output logic color_out_valid,
	
	// to stall the pipe
	input datapath_ready,
	
	output color_t color_out
);
	
	logic signed [8:0] sum;
	color_t color_out_next;
	logic overflow;
	logic sub;
	
	always_ff @(posedge clk or negedge resetN)
	begin
		if(~resetN) begin
			color_out <= MIN_COLOR;
			color_out_valid  <= 1'b0;
		end
			
		else if (datapath_ready) begin
			color_out <= color_out_next;
			color_out_valid <= color_in_valid;
		end
		
	end
	
	always_comb
	begin
		if (en_bp) begin
			sum = {1'b0, color_in} + brightness_param;
			overflow = sum[8] & brightness_param[8];
			sub = sum[8] & ~brightness_param[8];
			
			if ( overflow )
				color_out_next = MIN_COLOR;
			else if( sub )
				color_out_next = MAX_COLOR;
			else
				color_out_next = sum[7:0];
					
		end else begin
			color_out_next = color_in;
		end
	end
	

	
endmodule

