/*------------------------------------------------------------------------------
 * File          : tb_contrast_LUT.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 3, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/1ps
import pkg::*;

module tb_contrast_LUT;

	int fd;
	int fd_out;
	int img_height;
	int img_width;
	int img_size;
	int index_in;
	int index_tmp;
	
	logic en_cp;	
	logic invalid_cp_lut;
	contrast_fp_t contrast_fp;
	cp_param_t cp_param;
	color_t color_in_vec [];
	color_t color_in;
	color_t color_out;
	
	logic clk;
	logic resetN;
	
	initial begin
		// read test contrast_param
		fd = $fopen("contrast.LUT", "r");
		// Example: en_cp 1 contrast_fp 04		
		$display("read %d\n", $fscanf(fd, "en_cp %d contrast_fp %x",en_cp, contrast_fp));
		$fclose(fd);
		
		// reading image size from file, and creating dynamic array
		fd = $fopen("input_image.size", "r");
		$fscanf(fd, "%d\n%d", img_height, img_width);
		img_size = img_height * img_width;
		color_in_vec = new [img_size];
		$fclose(fd);
		
		// reading input image (hexa format from MATLAB), and loading to dynamic array
		index_tmp = 0;
		fd = $fopen("input_image.hex", "r");
		while ($fscanf(fd, "%x", color_in_vec[index_tmp]) == 1)begin
			index_tmp = index_tmp + 1;
		end
		index_tmp = 0;
		$fclose(fd);
		
		// open writing file output (image in hexa format)
		fd_out = $fopen("output_image.hex", "w");
		
		// setting initial signals
		clk = 1'b0;
		resetN = 1'b0;
		index_in = 0;
		#10 resetN = 1'b1;
	end
	
	// setting clk
	always begin
		#5 clk = ~clk;
	end
	
	always @(posedge clk) begin
		if (resetN) begin
			// updating each posedge clock next pixel input
			index_in = index_in + 1;
			if(index_in > img_size)begin
				$fclose(fd_out);
				$finish;			
			end
				color_in = color_in_vec[index_in];
			// assuming data will be ready in 1 clk cycle
		end
	end
	
	// writing image output file in hex format
	// print for fun
	always @(index_in) begin
		if (resetN) begin
			//$display("color pixel_vaule is --- %x\n", color_out);
			$fdisplay(fd_out, "%x", color_out);
		end
	end
	
	
	contrast_LUT contrast_LUT_inst (
	.clk(clk), .resetN(resetN), .en_cp(en_cp), .contrast_fp(contrast_fp),
	.cp_param(cp_param), .invalid(invalid_cp_lut)
);
	
	contrast contrast_inst (
		.clk(clk), .resetN(resetN), .en_cp(en_cp),
		.cp_param(cp_param), .color_in(color_in),
		.color_out(color_out)
		);

endmodule