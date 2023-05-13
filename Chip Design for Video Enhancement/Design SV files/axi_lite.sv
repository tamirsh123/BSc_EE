/*------------------------------------------------------------------------------
 * File          : axi_lite.vs
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 5, 2022
 * Description   : AXI-Lite Interface to internal IP, ACLK=clk
 *------------------------------------------------------------------------------*/

import pkg::*;

module axi_lite #() (
	input logic ACLK,
	input logic ARESETn,
	
	// we are the Slave
	// address always from MASTER
	
	// Write address channel (Master -> Slave)
	input PADDR AWADDR,
	input logic AWVALID,
	output logic AWREADY,
	
	// Write data channel (Master -> Slave)
	input PDATA WDATA,
	input logic WVALID,
	output logic WREADY,
	
	// Write response channel (Slave -> Master)
	output PRESP BRESP,
	output logic BVALID, //Valid = you have an answer
	input logic BREADY,  // Master ready to get response. END.
	
	// ASK PAVEL, maybe irrelevant ? //
	// Read address channel (Master -> Slave)
	input PADDR ARADDR,
	input logic ARVALID,
	output logic ARREADY,
	
	// Read data channel (Slave -> Master)
	input logic RREADY,
	output PDATA RDATA,
	output logic RVALID,
	output PRESP RRESP,
	
	
	// Internal side
	//
	input logic clk,
	input logic rst_n,
	
	// Write
	output logic pvalid,
	output PDATA pdata,
	output PADDR paddr,
	
	// Controller write response / new
	input PRESP cwresp,
	input logic cwresp_valid,	
	
	// Read
	output PADDR raddr,
	output logic raddr_valid,
	
	// Controller read response / new
	input logic crresp_valid,
	input PDATA rdata,
	input PRESP crresp
	
);
	// AXI side
	logic AWREADY_n, WREADY_n, BVALID_n, ARREADY_n, RVALID_n;
	assign AWREADY = ~AWREADY_n;
	assign WREADY=~WREADY_n;
	assign BVALID=~BVALID_n;
	assign ARREADY=~ARREADY_n;
	assign RVALID=~RVALID_n;
	
	// Internal side
	logic write_resp_fifo_push_full;
	logic write_addr_fifo_pop_empty;
	logic write_data_fifo_pop_empty;
	logic read_addr_fifo_pop_empty;
	logic read_data_fifo_push_full;
	
	// Only if both are not empty - the combination of paddr and pdata is valid.
	assign pvalid = ~(write_addr_fifo_pop_empty | write_data_fifo_pop_empty);
	assign raddr_valid = ~ read_addr_fifo_pop_empty;
	
	
	DW_fifo_s2_sf #(.width($size(AWADDR)), .depth(4), .push_ae_lvl(2), .push_af_lvl(2),
					.pop_ae_lvl(2), .pop_af_lvl(2), .err_mode(1), .push_sync(2), .pop_sync(2), .rst_mode(0))
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	write_addr_fifo(.rst_n(rst_n & ARESETn), 
		.clk_push(ACLK), .push_full(AWREADY_n), .push_req_n(~AWVALID), .data_in(AWADDR),
		.clk_pop(clk), .pop_empty(write_addr_fifo_pop_empty), .pop_req_n(write_resp_fifo_push_full), .data_out(paddr));
	
	DW_fifo_s2_sf #(.width($size(WDATA)), .depth(4), .push_ae_lvl(2), .push_af_lvl(2),
					.pop_ae_lvl(2), .pop_af_lvl(2), .err_mode(1), .push_sync(2), .pop_sync(2), .rst_mode(0))
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	write_data_fifo(.rst_n(rst_n & ARESETn), 
		.clk_push(ACLK), .push_full(WREADY_n), .push_req_n(~WVALID), .data_in(WDATA),
		.clk_pop(clk), .pop_empty(write_data_fifo_pop_empty), .pop_req_n(write_resp_fifo_push_full), .data_out(pdata));
	
	DW_fifo_s2_sf #(.width($size(BRESP)), .depth(4), .push_ae_lvl(2), .push_af_lvl(2),
					.pop_ae_lvl(2), .pop_af_lvl(2), .err_mode(1), .push_sync(2), .pop_sync(2), .rst_mode(0))	
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	write_resp_fifo(.rst_n(rst_n & ARESETn), 
		.clk_pop(ACLK), .pop_empty(BVALID_n), .pop_req_n(~BREADY), .data_out(BRESP),
		.clk_push(clk), .push_full(write_resp_fifo_push_full), .push_req_n(~cwresp_valid), .data_in(cwresp));

	DW_fifo_s2_sf #(.width($size(ARADDR)), .depth(4), .push_ae_lvl(2), .push_af_lvl(2),
					.pop_ae_lvl(2), .pop_af_lvl(2), .err_mode(1), .push_sync(2), .pop_sync(2), .rst_mode(0))	
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	read_addr_fifo(.rst_n(rst_n & ARESETn), 
		.clk_push(ACLK), .push_full(ARREADY_n), .push_req_n(~ARVALID), .data_in(ARADDR),
		.clk_pop(clk), .pop_empty(read_addr_fifo_pop_empty), .pop_req_n(read_data_fifo_push_full), .data_out(raddr));

	DW_fifo_s2_sf #(.width($size(rdata)+$size(crresp)), .depth(4), .push_ae_lvl(2), .push_af_lvl(2),
					.pop_ae_lvl(2), .pop_af_lvl(2), .err_mode(1), .push_sync(2), .pop_sync(2), .rst_mode(0))
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	read_data_fifo(.rst_n(rst_n & ARESETn), 
		.clk_pop(ACLK), .pop_empty(RVALID_n), .pop_req_n(~RREADY), .data_out({RDATA, RRESP}),
		.clk_push(clk), .push_full(read_data_fifo_push_full), .push_req_n(~crresp_valid), .data_in({rdata, crresp}));

endmodule