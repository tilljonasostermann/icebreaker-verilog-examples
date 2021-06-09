/*
 *  icebreaker examples - pdm demo
 *
 *  Copyright (C) 2018 Piotr Esden-Tempski <piotr@esden.net>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

// This example is based on the PDM module by Tommy Thorn
// You can find him on GitHub as @tommythorn
// The original is here:
// https://github.com/tommythorn/yari/blob/master/shared/rtl/soclib/pdm.v

// This example generates PDM (Pulse Density Modulation) to fade LEDs
// The intended result is opposite pulsating Red and Green LEDs
// on the iCEBreaker. The intended effect is that the two LED "breathe" in
// brigtness up and down in opposite directions.

module top (
	input CLK,
	output LEDG_N,
	input BTN_N,
	output [2:0] LED_RGB,
	output P2, // Debug pins 
	output P3, //
	output P4, //
	output P5, //
	output P6, //
	output P7  //
);

// Reset to DFU bootloader with a long button press
wire will_reboot;
dfu_helper #(
	.BTN_MODE(3)
) dfu_helper_I (
	.boot_sel (2'b00),
	.boot_now (1'b0),
	.btn_in   (BTN_N),
	.btn_tick (),
	.btn_val  (),
	.btn_press(),
	.will_reboot(will_reboot),
	.clk      (CLK),
	.rst      (0)
);
// Indicate when the button was pressed for long enough to trigger a
// reboot into the DFU bootloader.
// (LED turns off when the condition matches)
assign LEDG_N = will_reboot;


// Gamma value lookup table parameters
parameter G_PW = 8; // Number of input bits
parameter G_OW = 16; // Number of output bits

// Load the gamma value lookup table
reg [(G_OW-1):0] gamma_lut [0:((1<<(G_PW))-1)];
initial $readmemh("gamma_table.hex", gamma_lut);

// PDM generator
/*
 * Pulse Density Modulation for controlling LED intensity.
 * The theory is as follows:
 * given a desired target level 0 <= T <= 1, control the output pdm_out
 * in {1,0}, such that pdm_out on average is T. Do this by integrating the
 * error T - pdm_out over time and switch pdm_out such that the sum of
 * (T - pdm_out) is finite.
 *
 * pdm_sigma = 0, pdm_out = 0
 * forever
 *   pdm_sigma = pdm_sigma + (T - pdm_out)
 *   if (pdm_sigma >= 0)
 *     pdm_out = 1
 *   else
 *     pdm_out = 0
 *
 * Check: T = 0, pdm_out is never turned on; T = 1, pdm_out is olways on;
 *        T = 0.5, pdm_out toggles
 *
 * In fixed point arithmetic this becomes the following (assume N-bit arith)
 * pdm_sigma = pdm_sigma_float * 2^N = pdm_sigma_float << N.
 * As |pdm_sigma| <= 1, N+2 bits is sufficient
 *
 * pdm_sigma = 0, pdm_out = 0
 * forever
 *   D = T + (~pdm_out + 1) << N === T + (pdm_out << N) + (pdm_out << (N+1))
 *   pdm_sigma = pdm_sigma + D
 *   pdm_out = 1 & (pdm_sigma >> (N+1))
 */
reg [G_OW-1:0] pdm_level1;
reg [G_OW+1:0] pdm_sigma1;
reg pdm_out1;
assign pdm_out1 = ~pdm_sigma1[G_OW+1];
always @(posedge CLK) begin
	pdm_sigma1 <= pdm_sigma1 + {pdm_out1, pdm_out1, pdm_level1};
end

reg [G_OW-1:0] pdm_level2;
reg [G_OW+1:0] pdm_sigma2;
reg pdm_out2;
assign pdm_out2 = ~pdm_sigma2[G_OW+1];
always @(posedge CLK) begin
	pdm_sigma2 <= pdm_sigma2 + {pdm_out2, pdm_out2, pdm_level2};
end

// PDM level generator
// Fading up and down creating a slow sawtooth output
// The fade up down takes about 11.18 seconds
// Note: You will see that the LEDs spend more time being very bright
// than visibly fading, this is because our vision is non linear. Take a look
// at the pwm_fade_gamma example that fixes this issue. :)
reg [17:0] pdm_inc_counter = 0;
reg [G_PW-1+1:0] pdm_level_value;
reg [G_OW-1:0] pdm_gamma_level_p;
reg [G_OW-1:0] pdm_gamma_level_n;
always @(posedge CLK) begin
	// Divide clock by 131071
	pdm_inc_counter <= pdm_inc_counter + 1;

	// increment/decrement pwm compare value at 91.55Hz
	if (pdm_inc_counter[17]) begin
		pdm_inc_counter <= 0;
		pdm_level_value <= pdm_level_value + 1;
	end

	pdm_gamma_level_p <= gamma_lut[ pdm_level_value[G_PW-1:0]];
	pdm_gamma_level_n <= gamma_lut[~pdm_level_value[G_PW-1:0]];
end

assign pdm_level1 = pdm_level_value[G_PW-1+1] ? pdm_gamma_level_n : pdm_gamma_level_p;
assign pdm_level2 = pdm_level_value[G_PW-1+1] ? pdm_gamma_level_p : pdm_gamma_level_n;

SB_RGBA_DRV #(
	.CURRENT_MODE("0b1"), // 0: Normal; 1: Half
	// Set current to: 4mA
	// According to the datasheet the only accepted values are:
	// 0b000001, 0b000011, 0b000111, 0b001111, 0b011111, 0b111111
	// Each enabled bit increases the current by 4mA in normal CURRENT_MODE
	// and 2mA in half CURRENT_MODE.
	.RGB0_CURRENT("0b000001"),
	.RGB1_CURRENT("0b000001"),
	.RGB2_CURRENT("0b000001")
) rgb_drv_I (
	.RGBLEDEN(1'b1), // Global ON/OFF control
	.RGB0PWM(pdm_out1), // Single ON/OFF control that can accept PWM input
	.RGB1PWM(1'b0),
	.RGB2PWM(pdm_out2),
	.CURREN(1'b1), // Enable current reference
	.RGB0(LED_RGB[0]),
	.RGB1(LED_RGB[1]),
	.RGB2(LED_RGB[2])
);

assign P2 = pdm_inc_counter[15]; // 50% duty cycle PDM inc clock
assign P3 = pdm_out1; // PDM output on a GPIO pin
assign P4 = pdm_out2; // PDM output on a GPIO pin
assign P5 = pdm_inc_counter[15]; // 50% duty cycle PDM inc clock
assign P6 = pdm_out1; // PDM output on a GPIO pin
assign P7 = pdm_out2; // PDM output on a GPIO pin

endmodule