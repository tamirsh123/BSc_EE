/*------------------------------------------------------------------------------
 * File          : pkg.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 2, 2022
 * Description   :
 *------------------------------------------------------------------------------*/

package pkg;
	typedef enum bit {ADD, SUB} operation;
	
	parameter MIN_COLOR = 8'h00;
	parameter MAX_COLOR = 8'hFF;
	typedef logic unsigned [7:0] color_t;
	typedef logic	signed [8:0] color_signed_t;
	
	typedef color_t [2:0] RGB_t;
	
	typedef logic [3:0] shift_idx_t;
	typedef enum bit [1:0] {LEFT = 2'b10, RIGHT = 2'b01, ZERO = 2'b00} direction;
	typedef logic [1:0] shift_val_t;
	typedef logic unsigned [9:0] shifted_t;
	typedef logic signed [10:0] shifted_signed_t;
	
	typedef struct packed {
		direction dir;
		shift_val_t val;
	} shifter_t;
	
	typedef struct packed {
		logic sign;
		shifter_t shifter_b;
		shifter_t shifter_a;
	} cp_param_t;
	
	typedef logic unsigned [7:0] contrast_fp_t;
	
	parameter N_COLOR_TO_SHIFTED = $size(shifted_t)-$size(color_t);
	
	
	// AXI:
	// AXI-Lite:
	typedef logic unsigned [15:0] PDATA;
	typedef logic unsigned [15:0] PADDR;
	
	// In AXI-Lite only OKAY and SLVERR are used
	typedef enum logic [1:0] {OKAY, EXOKAY, SLVERR, DECERR} PRESP; 
	
	// AXI-Stream:
	typedef logic unsigned [31:0] FDATA;
	
	
	// Internal address space
	parameter logic [3:0] ADDR_ENABLES 		= 4'b0001;
	parameter logic [3:0] ADDR_BRIGHTNESS 	= 4'b0010;
	parameter logic [3:0] ADDR_CONTRAST 	= 4'b0100;
	parameter logic [3:0] ADDR_GAMMA_LUT 	= 4'b1000;
	
	
endpackage