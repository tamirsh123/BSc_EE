/*------------------------------------------------------------------------------
 * File          : shifter.sv
 * Project       : RTL
 * Author        : epttsm
 * Creation date : Jun 2, 2022
 * Description   :
 *------------------------------------------------------------------------------*/
import pkg::*;

module shifter #() (
	input color_t color_in,
	input shifter_t shifter_param,
	input logic shift_en,
	
	output shifted_t color_out
	);
	
	direction shift_direction;
	shift_val_t shift_by;
	
	assign shift_direction = shifter_param.dir;
	assign shift_by = shifter_param.val;
	
	always_comb
	begin
		// if shift_en ON
		if(shift_en) begin
			if(shift_direction == RIGHT) begin
				case(shift_by)
					2'd1: color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in} >> 1;
					2'd2: color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in} >> 2;
					2'd3: color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in} >> 3;
					default: color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in};
				endcase
			end
			
			else if(shift_direction == LEFT)begin
				case(shift_by)
					2'd1: color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in} << 1;
					2'd2: color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in} << 2;
					default: color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in};
				endcase
			end
			
			// if (direction == ZERO) -> output 0s
			else begin
				color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, MIN_COLOR};
			end
			
		end
		// if shift_en OFF, bypass
		else begin
			color_out = {{N_COLOR_TO_SHIFTED{1'b0}}, color_in};
		end
		
	end
	
	
endmodule