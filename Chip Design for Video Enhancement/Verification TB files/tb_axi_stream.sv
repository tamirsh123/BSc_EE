/*------------------------------------------------------------------------------
 * File          : tb_axi_stream.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 8, 2022
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns/1ps
import pkg::*;

module tb_axi_stream;

	int fd;
	int fd_out;
	int img_height;
	int img_width;
	int img_size;
	int index_in;
	int index_tmp;
	
	// datapath:
	RGB_t rgb_in_vec [];
	RGB_t rgb_in;
	RGB_t rgb_out;
	FDATA TDATA;
	
	// DUT connections:
	logic rgb_in_valid;
	// @SuppressProblem -type fully_unread_static_variable -count 1 -length 1
	logic rgb_out_valid;
	logic TVALID;
	logic TREADY;
	
	// @SuppressProblem -type fully_unread_static_variable -count 1 -length 1
	logic datapath_master_ready;
	logic datapath_slave_ready;

	logic clk_en;
	logic clk;
	logic resetN;

	
	initial begin
		
		// reading input signals for tb
		//fd = $fopen("tb_axi_stream.txt", "r");
		//$fscanf(fd, "datapath_slave_ready %d rgb_in_valid %d clk_en %d", datapath_slave_ready, rgb_in_valid, clk_en);
		//$display("datapath_slave_ready %d rgb_in_valid %d clk_en %d", datapath_slave_ready, rgb_in_valid, clk_en);
		//$fclose(fd);
		clk_en = 1'b1;
		
		// reading image size from file, and creating dynamic array
		fd = $fopen("input_image.size", "r");
		// @SuppressProblem -type function_with_side_effects_result_ignored -count 1 -length 1
		$fscanf(fd, "%d\n%d", img_height, img_width);
		img_size = img_height * img_width;
		rgb_in_vec = new [img_size];
		$fclose(fd);
		
		// reading input image (hexa format from MATLAB), and loading to dynamic array
		index_tmp = 0;
		fd = $fopen("input_image_old.hex", "r");
		while ($fscanf(fd, "%x", rgb_in_vec[index_tmp]) == 1)begin
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
	end
	
	// setting clk
	always begin
		#5 clk = ~clk;
	end
	
	// set and permutate signals
	always @(posedge clk) begin
		if (~resetN) begin
			rgb_in_valid <= 1'b0;
			datapath_slave_ready <= 1'b0;
		end
		else if (resetN) begin
			if (index_in % 4 == 0)
				rgb_in_valid <= ~rgb_in_valid;
			if (index_in % 8 == 0)
				datapath_slave_ready <= ~datapath_slave_ready;
		end
	end	
	// push framergb_in
	always @(posedge clk) begin
		// wait for glut writing to finish
		if (resetN) begin
			// updating each posedge clock next pixel input
			index_in = index_in + 1;
			if(index_in > img_size)begin
				$fclose(fd_out);
				$finish;			
			end
				rgb_in <= rgb_in_vec[index_in];
			// assuming data will be ready in 1 clk cycle
		end
	end
	
	// writing image output file in hex format
	// print for fun
	always @(index_in) begin
		if (resetN) begin
			//$display("color pixel_vaule is --- %x\n", rgb_out);
			$fdisplay(fd_out, "%x", rgb_out);
		end
	end
	
	axi_stream_master axi_stream_master_inst (
		.ACLK(clk), .ARESETn(resetN), .datapath_ready(datapath_master_ready),
		.TDATA(TDATA), .TVALID(TVALID), .TREADY(TREADY),
		.rgb_valid(rgb_in_valid),
		.rgb_in({8'b0, rgb_in})
		);
	
	axi_stream_slave axi_stream_slave_inst (
		.ACLK(clk), .ARESETn(resetN), .datapath_ready(datapath_slave_ready),
		.TDATA(TDATA), .TVALID(TVALID), .TREADY(TREADY), 
		.rgb_valid(rgb_out_valid),
		// @SuppressProblem -type port_connection_truncation_non_const_other -count 1 -length 1
		.rgb_out(rgb_out)
		);
	

	



endmodule