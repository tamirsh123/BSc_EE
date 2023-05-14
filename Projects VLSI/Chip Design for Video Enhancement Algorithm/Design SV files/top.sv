/*------------------------------------------------------------------------------
 * File          : top.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 7, 2022
 * Description   : Highest hierarchy level of design.
 *------------------------------------------------------------------------------*/
import pkg::*;

module top (
	
	input logic rst_n,

	// axi-lite interface
		input logic ACLK,
		input logic ARESETn,
		input PADDR AWADDR,
		input logic AWVALID,
		output logic AWREADY,
		input PDATA WDATA,
		input logic WVALID,
		output logic WREADY,
		output PRESP BRESP,
		output logic BVALID, 
		input logic BREADY,
		input PADDR ARADDR,
		input logic ARVALID,
		output logic ARREADY,
		input logic RREADY,
		output PDATA RDATA,
		output logic RVALID,
		output PRESP RRESP,
		
	// axi-stream upstream (slave) interface
		input logic up_ACLK,
		input logic up_ARESETn,
		input FDATA up_TDATA,
		input logic up_TVALID,
		output logic up_TREADY,
	
	// axi-stream downstream (master) interface
		output logic down_ACLK,
		output logic down_ARESETn,
		output FDATA down_TDATA,
		output logic down_TVALID,
		input  logic down_TREADY
);

	// clk is driven by external AXI-Stream upstream
	logic clk;
	assign clk = up_ACLK;
	// Parameters can be reset from AXI-Lite
	logic params_resetN;
	assign params_resetN = ARESETn;
	// Datapath / data out can be reset from AXI-Stream upstream
	logic datapath_resetN;
	assign datapath_resetN = up_ARESETn; 
	// passthrough signals from AXI-Stream upstream to downstream
	assign down_ACLK = up_ACLK;
	assign down_ARESETn = up_ARESETn;
	
	logic pvalid;
	PDATA pdata;
	PADDR paddr;
	PRESP cwresp;
	logic cwresp_valid;	
	PADDR raddr;
	logic raddr_valid;
	logic crresp_valid;
	PDATA rdata;
	PRESP crresp;
	
	PDATA glut_to_read;
	logic glut_write_en_n;
	logic g_en;
	cp_param_t cp_param;
	logic c_en;
	color_signed_t brightness_param;
	logic b_en;

	logic datapath_ready;
	logic rgb_in_valid;
	FDATA rgb_in;
	logic rgb_out_valid[3:0];
    FDATA rgb_out;
	

	axi_lite axi_lite_inst (
		.ACLK        (ACLK        ),
		.ARESETn     (ARESETn     ),
		.AWADDR      (AWADDR      ),
		.AWVALID     (AWVALID     ),
		.AWREADY     (AWREADY     ),
		.WDATA       (WDATA       ),
		.WVALID      (WVALID      ),
		.WREADY      (WREADY      ),
		.BRESP       (BRESP       ),
		.BVALID      (BVALID      ),
		.BREADY      (BREADY      ),
		.ARADDR      (ARADDR      ),
		.ARVALID     (ARVALID     ),
		.ARREADY     (ARREADY     ),
		.RREADY      (RREADY      ),
		.RDATA       (RDATA       ),
		.RVALID      (RVALID      ),
		.RRESP       (RRESP       ),
		.clk         (clk         ),
		.rst_n       (rst_n       ),
		.pvalid      (pvalid      ),
		.pdata       (pdata       ),
		.paddr       (paddr       ),
		.cwresp      (cwresp      ),
		.cwresp_valid(cwresp_valid),
		.raddr       (raddr       ),
		.raddr_valid (raddr_valid ),
		.crresp_valid(crresp_valid),
		.rdata       (rdata       ),
		.crresp      (crresp      )
	);
	
	controller controller_inst (
		.clk             (clk             ),
		.rst_n           (rst_n           ),
		.params_resetN   (params_resetN   ),
		.pvalid          (pvalid          ),
		.pdata           (pdata           ),
		.paddr           (paddr           ),
		.raddr_valid     (raddr_valid     ),
		.raddr           (raddr           ),
		.cwresp          (cwresp          ),
		.cwresp_valid    (cwresp_valid    ),
		.rdata           (rdata           ),
		.crresp          (crresp          ),
		.crresp_valid    (crresp_valid    ),
		.glut_to_read    (glut_to_read    ),
		.glut_write_en_n (glut_write_en_n ),
		.g_en            (g_en            ),
		.cp_param     	 (cp_param        ),
		.c_en            (c_en            ),
		.brightness_param(brightness_param),
		.b_en            (b_en            )
	);
	
	axi_stream_slave axi_stream_slave_inst (
		.resetN        (rst_n            ),
		.ACLK          (up_ACLK          ),
		.ARESETn       (up_ARESETn       ),
		.datapath_ready(datapath_ready	 ),
		.TDATA         (up_TDATA         ),
		.TVALID        (up_TVALID        ),
		.TREADY        (up_TREADY        ),
		.rgb_valid     (rgb_in_valid     ),
		.rgb_out       (rgb_in      	 )
	);
	
	datapath_channel datapath_channel_R (
		.clk             (clk             ),
		.resetN          (rst_n           ),
		.datapath_resetN (datapath_resetN ),
		.params_resetN   (params_resetN   ),
		.glut_write_en_n (glut_write_en_n ),
		.g_en            (g_en            ),
		.c_en            (c_en            ),
		.b_en            (b_en            ),
		.color_in_valid  (rgb_in_valid    ),
		.datapath_ready  (datapath_ready  ),
		.color_in        (rgb_in[7:0]     ),
		.color_out       (rgb_out[7:0]    ),
		.color_out_valid (rgb_out_valid[0]),
		.glut_from       (paddr           ),
		.glut_to         (pdata           ),
		.cp_param        (cp_param        ),
		.brightness_param(brightness_param),
		.glut_from_read  (raddr           ),
		.glut_to_read    (glut_to_read)
	);
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	datapath_channel datapath_channel_G (
		.clk             (clk             ),
		.resetN          (rst_n           ),
		.datapath_resetN (datapath_resetN ),
		.params_resetN   (params_resetN   ),
		.glut_write_en_n (glut_write_en_n ),
		.g_en            (g_en            ),
		.c_en            (c_en            ),
		.b_en            (b_en            ),
		.color_in_valid  (rgb_in_valid    ),
		.datapath_ready  (datapath_ready  ),
		.color_in        (rgb_in[15:8]    ),
		.color_out       (rgb_out[15:8]   ),
		.color_out_valid (rgb_out_valid[1]),
		.glut_from       (paddr           ),
		.glut_to         (pdata           ),
		.cp_param        (cp_param        ),
		.brightness_param(brightness_param),
		.glut_from_read  (raddr           )
		//.glut_to_read  ()
	);
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	datapath_channel datapath_channel_B (
		.clk             (clk             ),
		.resetN          (rst_n           ),
		.datapath_resetN (datapath_resetN ),
		.params_resetN   (params_resetN   ),
		.glut_write_en_n (glut_write_en_n ),
		.g_en            (g_en            ),
		.c_en            (c_en            ),
		.b_en            (b_en            ),
		.color_in_valid  (rgb_in_valid    ),
		.datapath_ready  (datapath_ready  ),
		.color_in        (rgb_in[23:16]   ),
		.color_out       (rgb_out[23:16]  ),
		.color_out_valid (rgb_out_valid[2]),
		.glut_from       (paddr           ),
		.glut_to         (pdata           ),
		.cp_param        (cp_param        ),
		.brightness_param(brightness_param),
		.glut_from_read  (raddr           )
		//.glut_to_read  ()
	);
	// @SuppressProblem -type unconnected_instance_port -count 1 -length 1
	// Meta data
	datapath_channel datapath_channel_M (
		.clk             (clk             ),
		.resetN          (rst_n           ),
		.datapath_resetN (datapath_resetN ),
		.params_resetN   (1'b1            ),
		.glut_write_en_n (1'b1            ),
		.g_en            (1'b0            ),
		.c_en            (1'b0            ),
		.b_en            (1'b0            ),
		.color_in_valid  (rgb_in_valid    ),
		.datapath_ready  (datapath_ready  ),
		.color_in        (rgb_in[31:24]   ),
		.color_out       (rgb_out[31:24]  ),
		.color_out_valid (rgb_out_valid[3]),
		.glut_from       (16'b0           ),
		.glut_to         (16'b0           ),
		.cp_param        (9'b0            ),
		.brightness_param(9'b0            ),
		.glut_from_read  (16'b0           )
		//.glut_to_read  ()
	);
		
	axi_stream_master axi_stream_master_inst (
		.resetN        (rst_n              ),
		.ACLK          (up_ACLK            ),
		.ARESETn       (up_ARESETn         ),
		.rgb_valid     (rgb_out_valid[0] & rgb_out_valid[1] & rgb_out_valid[2] & rgb_out_valid[3]),
		.rgb_in        (rgb_out            ),
		.datapath_ready(datapath_ready     ),
		.TDATA         (down_TDATA         ),
		.TVALID        (down_TVALID        ),
		.TREADY        (down_TREADY        )
	);
	
	
	
endmodule