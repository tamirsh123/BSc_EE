/*------------------------------------------------------------------------------
 * File          : contrast_LUT.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 4, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
import pkg::*;

module contrast_LUT #() (
	input logic clk,
	input logic resetN,
	
	input logic cp_write_en, 
	// @SuppressProblem -type partially_unread_data -count 1 -length 1
	input  PDATA pdata,
	output color_t contrast_fp,

	output cp_param_t cp_param,
	output logic invalid
);
	cp_param_t next_cp_param;
	
	always_ff @(posedge clk or negedge resetN)
	begin
		if(~resetN) begin
			cp_param <= 9'b0;
			contrast_fp <= 8'b0;
		end
		else if(cp_write_en & ~invalid) begin
			contrast_fp <= pdata[7:0];
			cp_param <= next_cp_param;
		end
	end

	always_comb
	begin
		invalid = 1'b0;
		case(pdata[7:0])
			8'b00000000: next_cp_param=9'b000000000;  //0x00 contrast_fp=0
			8'b00000001: next_cp_param=9'b000000111;  //0x01 contrast_fp=0.125
			8'b00000010: next_cp_param=9'b000000110;  //0x02 contrast_fp=0.25
			8'b00000011: next_cp_param=9'b001110110;  //0x03 contrast_fp=0.375
			8'b00000100: next_cp_param=9'b000000101;  //0x04 contrast_fp=0.5
			8'b00000101: next_cp_param=9'b001110101;  //0x05 contrast_fp=0.625
			8'b00000110: next_cp_param=9'b001100101;  //0x06 contrast_fp=0.75
			8'b00000111: next_cp_param=9'b101110100;  //0x07 contrast_fp=0.875
			8'b00001000: next_cp_param=9'b000000100;  //0x08 contrast_fp=1
			8'b00001001: next_cp_param=9'b001000111;  //0x09 contrast_fp=1.125
			8'b00001010: next_cp_param=9'b001000110;  //0x0A contrast_fp=1.25
			8'b00001100: next_cp_param=9'b001000101;  //0x0C contrast_fp=1.5
			8'b00001110: next_cp_param=9'b101101001;  //0x0E contrast_fp=1.75
			8'b00001111: next_cp_param=9'b101111001;  //0x0F contrast_fp=1.875
			8'b00010000: next_cp_param=9'b000001001;  //0x10 contrast_fp=2
			8'b00010001: next_cp_param=9'b010010111;  //0x11 contrast_fp=2.125
			8'b00010010: next_cp_param=9'b010010110;  //0x12 contrast_fp=2.25
			8'b00010100: next_cp_param=9'b010010101;  //0x14 contrast_fp=2.5
			8'b00011000: next_cp_param=9'b001001001;  //0x18 contrast_fp=3
			8'b00011100: next_cp_param=9'b101011010;  //0x1C contrast_fp=3.5
			8'b00011110: next_cp_param=9'b101101010;  //0x1E contrast_fp=3.75
			8'b00011111: next_cp_param=9'b101111010;  //0x1F contrast_fp=3.875
			8'b00100000: next_cp_param=9'b000001010;  //0x20 contrast_fp=4
			8'b00100001: next_cp_param=9'b010100111;  //0x21 contrast_fp=4.125
			8'b00100010: next_cp_param=9'b010100110;  //0x22 contrast_fp=4.25
			8'b00100100: next_cp_param=9'b010100101;  //0x24 contrast_fp=4.5
			8'b00101000: next_cp_param=9'b010100100;  //0x28 contrast_fp=5
			8'b00110000: next_cp_param=9'b010101001;  //0x30 contrast_fp=6
		
		default:
			begin
				//send error to controller
				invalid = 1'b1;
				next_cp_param = 9'b000000100;	//0x08 contrast_fp=1
			end
		endcase
	end

endmodule