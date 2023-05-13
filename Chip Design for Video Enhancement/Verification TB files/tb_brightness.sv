/*------------------------------------------------------------------------------
 * File          : tb.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 2, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/1ps

module tb_brightness;

	int fd;
	int fd_out;
	int img_height;
	int img_width;
	int img_size;
	logic unsigned [7:0] color_in_vec [];
	logic unsigned [7:0] color_in;
	logic unsigned [7:0] color_out;
	int index_in;
	int index_tmp;
			
	logic clk;
	logic resetN;
	
	initial begin
		
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
			$display("color pixel_vaule is --- %x\n", color_out);
			$fdisplay(fd_out, "%x", color_out);
		end
	end
		
	
	// @SuppressProblem -type port_connection_truncation_const_value_unchanged -count 1 -length 1
	brightness brightness_inst(.clk(clk), .resetN(resetN), .en_bp(1'b1), .brightness_param(1), 
		.color_in(color_in), .color_out(color_out) 
	);
		
endmodule