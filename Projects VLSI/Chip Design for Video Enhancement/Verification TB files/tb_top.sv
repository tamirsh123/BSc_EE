/*------------------------------------------------------------------------------
 * File          : tb_top.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Nov 5, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/1ns
import pkg::*;

module tb_top #() ();
	// TB parameters
	localparam AXI_LITE_PERIOD = 20; //ns
	// assigned to internal clk
	localparam AXI_STREAM_PERIOD = 10; //ns

	// TB params input - AXI-Lite -> DUT
	string top_signals_file;
	localparam AXI_LITE_TRANSACTIONS_MAX = 300;
	int axi_lite_transactions;	// In total
	int axi_lite_transaction;	// Current
	int wait_ACLKS;				// Current
	int wait_ACLKS_vec[AXI_LITE_TRANSACTIONS_MAX];
	logic ARESETn_vec[AXI_LITE_TRANSACTIONS_MAX];
	PADDR AWADDR_vec[AXI_LITE_TRANSACTIONS_MAX];
	logic AWVALID_vec[AXI_LITE_TRANSACTIONS_MAX];
	PDATA WDATA_vec[AXI_LITE_TRANSACTIONS_MAX];
	logic WVALID_vec[AXI_LITE_TRANSACTIONS_MAX];
	logic BREADY_vec[AXI_LITE_TRANSACTIONS_MAX];
	PADDR ARADDR_vec[AXI_LITE_TRANSACTIONS_MAX];
	logic ARVALID_vec[AXI_LITE_TRANSACTIONS_MAX];
	logic RREADY_vec[AXI_LITE_TRANSACTIONS_MAX];
	string AXI_Lite_comment_vec[AXI_LITE_TRANSACTIONS_MAX];

	// TB image input - AXI-Stream upstream->DUT
	int fd;
	int fd_out;
	int img_height;	// used only to calc stream_size
	int img_width;	// used only to calc stream_size
	int rgb_channels;
	int frames;
	
	int stream_size;	// to finish tb
	int index_in;	
	int index_tmp;
	FDATA up_TDATA_vec [];
	
	// DUT connections
	logic resetN;
	// axi-lite interface
		 logic ACLK;
		 logic ARESETn;
		 PADDR AWADDR;
		 logic AWVALID;
		 logic AWREADY;
		 PDATA WDATA;
		 logic WVALID;
		 logic WREADY;
		 PRESP BRESP;
		 logic BVALID; 
		 logic BREADY;
		 PADDR ARADDR;
		 logic ARVALID;
		 logic ARREADY;
		 logic RREADY;
		 PDATA RDATA;
		 logic RVALID;
		 PRESP RRESP;
		
	// axi-stream upstream (slave) interface
		 logic up_ACLK;
		 logic up_ARESETn;
		 FDATA up_TDATA;
		 logic up_TVALID;
		 logic up_TREADY;
	
	// axi-stream downstream (master) interface
		 logic down_ACLK;
		 logic down_ARESETn;
		 FDATA down_TDATA;
		 logic down_TVALID;
		 logic down_TREADY;
	
	// @SuppressProblem -type fully_unread_static_variable -count 1 -length 1
	string AXI_Lite_comment;

	initial begin
		// Read testbench AXI-Lite transactions
		axi_lite_transactions = 0;
		fd = $fopen("tb_top_signals_path.txt", "r");
		void'($fscanf(fd, "%s", top_signals_file));
		$fclose(fd);
		fd = $fopen(top_signals_file, "r");
		while ($fscanf(fd, "%d,%d,%b,%d,%b,%d,%b,%b,%b,%d,%b,%b,%s",
				wait_ACLKS_vec[axi_lite_transactions],
				ARESETn_vec[axi_lite_transactions],
				AWADDR_vec[axi_lite_transactions][15:12],
				AWADDR_vec[axi_lite_transactions][7:0],
				AWVALID_vec[axi_lite_transactions],
				WDATA_vec[axi_lite_transactions],
				WVALID_vec[axi_lite_transactions],
				BREADY_vec[axi_lite_transactions],
				ARADDR_vec[axi_lite_transactions][15:12],
				ARADDR_vec[axi_lite_transactions][7:0],
				ARVALID_vec[axi_lite_transactions],
				RREADY_vec[axi_lite_transactions],
				AXI_Lite_comment_vec[axi_lite_transactions]
				) == 13) begin
			axi_lite_transactions = axi_lite_transactions + 1;
		end
		$display("read %d transactions from %s\n", axi_lite_transactions, top_signals_file);
		
		
		// Read stream size from file, and create dynamic array
		fd = $fopen("input_stream.size", "r");
		$fscanf(fd, "%d\n%d\n%d\n%d", img_height, img_width, rgb_channels, frames);
		stream_size = img_height * img_width * frames;
		up_TDATA_vec = new [stream_size];
		$fclose(fd);
		// Read input stream (hexa format from MATLAB), and load to dynamic array
		index_tmp = 0;
		fd = $fopen("input_stream.hex", "r");
		while ($fscanf(fd, "%x", up_TDATA_vec[index_tmp]) == 1) begin
			index_tmp = index_tmp + 1;
		end
		index_tmp = 0;
		$fclose(fd);
		
		// open writing file output (image in hexa format)
		fd_out = $fopen({"output_stream_", top_signals_file, ".hex"}, "w");
		$display("Outputing stream to %s\n", {"output_stream_", top_signals_file, ".hex"});
		
		ACLK = 1'b0;
		up_ACLK = 1'b0;
		resetN = 1'b0;
		#AXI_LITE_PERIOD resetN = 1'b1;
		index_in = 0;
		
		up_ARESETn = 1'b0;
		#AXI_LITE_PERIOD up_ARESETn = 1'b1;
		up_TVALID = 1'b0;
		
		down_TREADY = 1'b1;	// TODO what if downstream not ready?
	end
	

	
// AXI-Lite -----------------------------------------------------------------------------------	
	// ACLK toggle
	localparam ACLK_T = 0.5*AXI_LITE_PERIOD;
	always begin
		#ACLK_T ACLK = ~ACLK;
	end
	
	
	// push user's signals (through AXI-Lite)
	always @(posedge ACLK or negedge resetN) begin
		// TODO replace with start signal from initial begin
		if(~resetN) begin
			wait_ACLKS <= 0;
			axi_lite_transaction <= 0;
		end
		else if((wait_ACLKS <= 0) & (axi_lite_transaction < axi_lite_transactions)) begin
			// finished wait - move to next transaction for 1 ACLK
			wait_ACLKS <= wait_ACLKS_vec[axi_lite_transaction];
			ARESETn	<= ARESETn_vec[axi_lite_transaction];
			AWADDR 	<= {AWADDR_vec[axi_lite_transaction][15:12], 4'b0, AWADDR_vec[axi_lite_transaction][7:0]};
			AWVALID <= AWVALID_vec[axi_lite_transaction];
			WDATA	<= WDATA_vec[axi_lite_transaction];
			WVALID	<= WVALID_vec[axi_lite_transaction];
			BREADY	<= BREADY_vec[axi_lite_transaction];
			ARADDR	<= {ARADDR_vec[axi_lite_transaction][15:12], 4'b0, ARADDR_vec[axi_lite_transaction][7:0]};
			ARVALID <= ARVALID_vec[axi_lite_transaction];
			RREADY	<= RREADY_vec[axi_lite_transaction];
			AXI_Lite_comment = AXI_Lite_comment_vec[axi_lite_transaction];
			axi_lite_transaction <= axi_lite_transaction + 1;
		end
		else begin
			// drop all signals to default and wait as defined in transaction
			wait_ACLKS <= wait_ACLKS - 1;
			ARESETn	<= 1'b1;
			AWADDR 	<= 16'b0;
			AWVALID <= 1'b0;
			WDATA	<= 16'b0;
			WVALID	<= 1'b0;
			BREADY	<= 1'b1;	// Master ready to get write response
			ARADDR	<= 16'b0;
			ARVALID <= 1'b0;
			RREADY	<= 1'b1;	// Master ready to get read response
			AXI_Lite_comment = "default";
		end
	end
	
	
// AXI-Stream upstream ------------------------------------------------------------------------
	// up_ACLK toggle
	localparam up_ACLK_T = 0.5*AXI_STREAM_PERIOD;
	always begin
		#up_ACLK_T up_ACLK = ~up_ACLK;
	end
	
	// TODO what if downstream not ready?
	// push frame
	always @(posedge up_ACLK or negedge up_ARESETn) begin
		if (up_ARESETn) begin
			// updating each posedge clock next pixel input
			up_TDATA <= up_TDATA_vec[index_in];
			up_TVALID <= 1'b1;
			index_in = index_in + 1;
			// assuming data will be ready in 1 up_ACLK cycle
		end
		// !up_ARESETn
		else begin
			up_TDATA <= 0;
			up_TVALID <= 1'b0;
		end
	end
	
	always @(posedge up_ACLK) begin
		if(index_in > stream_size) begin
			$fdisplay(fd_out, "00,00,00,00");
			$fdisplay(fd_out, "00,00,00,00");
			$fdisplay(fd_out, "00,00,00,00");
			$fdisplay(fd_out, "00,00,00,00");
			$fdisplay(fd_out, "00,00,00,00");
			$fdisplay(fd_out, "00,00,00,00");
			$fclose(fd_out);
			$finish;
		end
	end
	
	
// AXI-Stream downstream ----------------------------------------------------------------------
	// writing image output file in hex format
	always @(index_in) begin
		if (resetN & down_TVALID) begin
			$fdisplay(fd_out, "%x,%x,%x,%x",down_TDATA[31:24], down_TDATA[23:16], down_TDATA[15:8], down_TDATA[7:0]);
		end
	end
	
	
	top top_inst (
		.rst_n       (resetN      ),
		// AXI-Lite as slave
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
		// AXI-Stream upstream
		.up_ACLK     (up_ACLK     ),
		.up_ARESETn  (up_ARESETn  ),
		.up_TDATA    (up_TDATA    ),
		.up_TVALID   (up_TVALID   ),
		.up_TREADY   (up_TREADY   ),
		// AXI-Stream downstream
		.down_ACLK   (down_ACLK   ),
		.down_ARESETn(down_ARESETn),
		.down_TDATA  (down_TDATA  ),
		.down_TVALID (down_TVALID ),
		.down_TREADY (down_TREADY )
	);
	

endmodule
