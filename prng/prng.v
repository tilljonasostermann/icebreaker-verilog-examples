/*
 *  icebreaker examples - clk demo
 *
 *  Copyright (C) 2021 Till-Jonas Ostermann <till.ostermann@posteo.de>
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

// This example a small, simple example to generate a pseudo random number output on P1A9

module top (
	input CLK,
	input BTN_N,
    output P1A7,
    output P1A8,
    output LEDG_N
);


// Generate slow clock from 12MHz main oscillator frequency
// Clock output test
// clock devider
// hardcoded comperator number can be used to create required output frequency
// by default, the main clock is 12MHz on the iCEBreaker, the output is devided here to 10kHz
reg [9:0] CLK_counter = 0;
always @(posedge CLK) begin
    CLK_counter = CLK_counter+1;

    if (CLK_counter >= 600) begin
        CLK_counter <= 0;
        P1A8 = ~P1A8;
    end
end


// Psydo random numbers
// Small block to create a random output stream, called on the CLK signal generated and outputed on P1A8
reg [3:0] b;

//LFSR feedback bit
wire feedback;
assign feedback = b[0] ^ b[3];

// Add active low reset to sensitivity list
always@(posedge P1A8 or negedge BTN_N) begin
 if (BTN_N==1'b0) begin
  b[3:0]<=4'hF;  //reset condition first
  //LEDG_N <= ~LEDG_N; 
 end 
 else begin
  //Alternative Verilog might be
  b = {b[2:0], feedback};
 end
end

// assign the output signals to the ports
assign P1A7 = b[0]; // pseudo random output
assign P1A8 = CLK_375kHz; // 1.5MHz clock

endmodule
