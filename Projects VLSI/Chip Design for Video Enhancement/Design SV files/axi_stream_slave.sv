/*------------------------------------------------------------------------------
 * File          : axi_stream_slave.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 5, 2022
 * Description   :
 *------------------------------------------------------------------------------*/

import pkg::*;

module axi_stream_slave #() (
	input logic resetN,
	input logic ACLK,
	input logic ARESETn,
	
	// To stall input stream when downstream stalls
	input logic datapath_ready,
	
	// Write data stream (Master -> Slave)
	input FDATA TDATA,
	input logic TVALID,
	output logic TREADY,
	output logic rgb_valid,
	output FDATA rgb_out
);

	FDATA reg_rgb_out;
	assign rgb_out = reg_rgb_out;
	
	//write data handshake
	always @(posedge ACLK or negedge ARESETn or negedge resetN)
	begin
		if(~ARESETn) begin
			TREADY <= 1'b0;
		end
		else if(~resetN) begin
			TREADY <= 1'b0;
		end
		else begin
			TREADY <= datapath_ready;
		end
	end

	
	//latching logic
	always @(posedge ACLK or negedge ARESETn or negedge resetN)
	begin
		if(~ARESETn) begin
			reg_rgb_out <= 32'b0;
			rgb_valid <= 1'b0;
		end
		else if(~resetN) begin
			reg_rgb_out <= 32'b0;
			rgb_valid <= 1'b0;
		end
		else if(TVALID & TREADY) begin
			//look for data handshake
			reg_rgb_out <= TDATA;
			rgb_valid <= 1'b1;
		end
		else begin
			rgb_valid <= 1'b0;
		end
	end

endmodule