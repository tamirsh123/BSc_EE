/*------------------------------------------------------------------------------
 * File          : axi_stream_master.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 8, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
import pkg::*;

module axi_stream_master #() (
	input logic resetN,
	input logic ACLK,
	input logic ARESETn,
	
	// To allow only valid data
	input logic rgb_valid,
	input FDATA rgb_in,

	// To stall input stream when downstream stalls
	output logic datapath_ready,
	
	// Write data stream (Master -> Slave)
	output FDATA TDATA,
	output logic TVALID,
	input logic TREADY
);
	FDATA reg_rgb_out;
	assign TDATA = reg_rgb_out;
	
	// Indicates if slave is ready to receive new data
	logic slave_ready;
	assign datapath_ready = slave_ready;
	
	always_comb begin
		// Current data has not yet been read by slave - can't send new data
		if(~TREADY & TVALID) begin
			slave_ready = 1'b0;
		end
		// Previous data has been read by slave - can send new data
		else begin
			slave_ready = 1'b1;
		end
	end
	
	always @(posedge ACLK or negedge ARESETn or negedge resetN)
	begin
		if(~ARESETn) begin
			reg_rgb_out <= 32'b0;
			TVALID <= 1'b0;
		end
		else if(~resetN) begin
			reg_rgb_out <= 32'b0;
			TVALID <= 1'b0;
		end
		else begin
			if(slave_ready) begin
				if(rgb_valid) begin
					// Do send and raise valid
					reg_rgb_out <= rgb_in;
					TVALID <= 1'b1;
				end
				else begin
					// No new data to send, but previous read by slave
					TVALID <= 1'b0;
				end
			end
		end
	end
	
	

endmodule
