/*------------------------------------------------------------------------------
 * File          : tb_axi_stream_datapath.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 8, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/1ps
import pkg::*;

module tb_axi_stream_datapath;

	int fd;
	int fd_out;
	int img_height;
	int img_width;
	int img_size;
	int index_in;
	int index_tmp;
	
	// datapath:
	color_t color_in_vec [];
	color_t color_in;
	color_t color_out;
	FDATA TDATA;
	
	// DUT connections:
	logic color_in_valid;
	logic datapath_ready;
	logic color_out_valid;
	logic glut_write_en_n;
	logic g_en;
	logic c_en;
	logic b_en;

	
	// values read to tb:
	logic tb_g_en;
	logic tb_c_en;
	logic tb_b_en;
			
	// gamma:
	PADDR glut_from;
	PDATA glut_to;
	int index_glut;
	PADDR glut_from_vec [256];
	PDATA glut_to_vec [256];
	
	// contrast:
	logic invalid_cp_lut;
	contrast_fp_t contrast_fp;
	cp_param_t cp_param;
	
	// brigthness:
	color_signed_t brightness_param;

	logic clk;
	logic resetN;

	
	initial begin
		// read gamma LUT file
		index_glut = 0;
		fd = $fopen("gamma.LUT", "r");
		// Example: en_g 0
		$display("read %d\n", $fscanf(fd, "en_g %d", tb_g_en));
		while ($fscanf(fd, "%x %x", glut_from_vec[index_glut], glut_to_vec[index_glut]) == 2) begin
			//$display("glut_from: %x ,glut_to: %x\n", glut_from_vec[index_glut], glut_to_vec[index_glut]);
			index_glut = index_glut + 1;
		end
		$fclose(fd);
		
		if (index_glut != 256)
			$display("gamma.LUT has %d instead of 2^8=256", index_glut);
		

		// read test contrast_param
		fd = $fopen("contrast.LUT", "r");
		// Example: en_cp 1 contrast_fp 04
		$display("read %d\n", $fscanf(fd, "en_cp %d contrast_fp %x", tb_c_en, contrast_fp));
		$fclose(fd);
		
		// read test brightness param
		fd = $fopen("brightness", "r");
		// Example: en_bp 1 brightness_param F7
		$display("read %d\n", $fscanf(fd, "en_bp %d brightness_param %d", tb_b_en, brightness_param));
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
		
		clk = 1'b0;
		resetN = 1'b0;
		index_in = 0;
		#10 resetN = 1'b1;
		index_in = 0;
		
		// load gamma LUT
		g_en = 1'b0; b_en = 1'b0; c_en = 1'b0;
		glut_write_en_n = 1'b0;
		
	end
	
	// setting clk
	always begin
		#5 clk = ~clk;
	end
	
	// push gamma LUT
	always @(posedge clk) begin
		if (resetN & ~glut_write_en_n) begin
			index_glut = index_glut - 1;
			if(index_glut < 0) begin
				// finished pushing gamma LUT
				glut_write_en_n <= 1'b1;
				g_en <= tb_g_en; b_en <= tb_b_en; c_en <= tb_c_en;
			end
			else begin
				glut_from <= glut_from_vec[index_glut];
				glut_to <= glut_to_vec[index_glut];
			end
		end
	end
	
	// push frame
	always @(posedge clk) begin
		// wait for glut writing to finish
		if (resetN & glut_write_en_n) begin
			// updating each posedge clock next pixel input
			index_in = index_in + 1;
			if(index_in > img_size)begin
				$fclose(fd_out);
				$finish;			
			end
				color_in <= color_in_vec[index_in];
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
	
	axi_stream_slave axi_stream_slave_inst (
		.ACLK(clk), .ACLKEN(1'b1), .ARESETn(resetN), .datapath_ready(datapath_ready),
		.TDATA(TDATA), .TVALID(c_en), .TREADY(b_en), 
		.rgb_valid(datapath_ready),
		.rgb_out(color_in)
		);
	
	
	contrast_LUT contrast_LUT_inst (
	.clk(clk), .resetN(resetN), .en_cp(c_en), .contrast_fp(contrast_fp),
	.cp_param(cp_param), .invalid(invalid_cp_lut)
);
	
	datapath_channel datapath_channel_inst (
		.clk(clk), .resetN(resetN), .glut_write_en_n(glut_write_en_n),
		.g_en(g_en), .c_en(c_en), .b_en(b_en), 
		.datapath_ready(datapath_ready),
		.color_in(color_in), .color_in_valid(color_in_valid),
		.color_out(color_out), .color_out_valid(color_out_valid),
		.glut_from(glut_from), .glut_to(glut_to),
		.cp_param(cp_param), .brightness_param(brightness_param)
		);


endmodule