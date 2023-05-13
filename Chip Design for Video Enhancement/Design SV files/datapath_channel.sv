/*------------------------------------------------------------------------------
 * File          : datapath_channel.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Oct 7, 2022
 * Description   : Datapath for a single color channel
 *------------------------------------------------------------------------------*/

import pkg::*;

module datapath_channel #() (
	input logic clk,
	input logic resetN,
	// Resets data out only w/o resetting RAM
	input logic datapath_resetN,
	// Resets RAM only w/o resetting datapath
	input logic params_resetN,
	
	// All-channel control
	input logic glut_write_en_n,
	input logic g_en,
	input logic c_en,
	input logic b_en,
	input logic color_in_valid,
	input logic datapath_ready,
	
	input color_t color_in,
	output color_t color_out,
	output logic color_out_valid,
	
	// Cross-channel parameters
	input PADDR glut_from,
	input PDATA glut_to,
	input cp_param_t cp_param,
	input color_signed_t brightness_param,
	
	// gamma LUT read
	input PADDR glut_from_read,
	output PDATA glut_to_read
);
	color_t gamma_out;
	color_t contrast_out;
	color_t brightness_out;
	logic gamma_out_valid;
	logic contrast_out_valid;
	logic brightness_out_valid;
	
	assign color_out = brightness_out;
	assign color_out_valid = brightness_out_valid;
	
	gamma_LUT gamma_LUT_inst (
		.clk(clk),
		.resetN(resetN),
		.datapath_resetN(datapath_resetN),
		.params_resetN(params_resetN),
		.g_en(g_en),
		.datapath_ready(datapath_ready),
		.color_in(color_in),
		.color_in_valid(color_in_valid),
		.color_out(gamma_out),
		.color_out_valid(gamma_out_valid),
		.glut_write_en_n(glut_write_en_n),
		.paddr(glut_from),
		.pdata(glut_to),
		.raddr(glut_from_read),
		.glut_rdata(glut_to_read)
		
	);
	
	contrast contrast_inst(
		.clk(clk),
		.resetN(resetN & datapath_resetN),
		.en_cp(c_en),
		.datapath_ready(datapath_ready),
		.cp_param(cp_param),
		.color_in(gamma_out),
		.color_in_valid(gamma_out_valid),
		.color_out(contrast_out),
		.color_out_valid(contrast_out_valid)
	);
	
	brightness brightness_inst(
		.clk(clk),
		.resetN(resetN & datapath_resetN),
		.en_bp(b_en),
		.datapath_ready(datapath_ready),
		.brightness_param(brightness_param),
		.color_in(contrast_out),
		.color_in_valid(contrast_out_valid),
		.color_out(brightness_out),
		.color_out_valid(brightness_out_valid)
	);
	
endmodule