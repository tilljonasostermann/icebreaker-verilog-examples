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

// This example a small getting started code to test the iCEBreaker

module top (
	input CLK,
	input BTN_N,
	output P1A7,
	output P1A8
);

// Clock output test
// half clock speed, as always switch only occurs on the posedge
// by default, the main clock is 12MHz on the iCEBreaker, the output 6MHz
always @(posedge CLK) begin
    P1A7 = ~P1A7;
end

// Clock output test
// clock devider
// hardcoded comperator number can be used to create required output frequency
// by default, the main clock is 12MHz on the iCEBreaker, the output 60kHz
reg [7:0] CLK_counter = 0;
always @(posedge CLK) begin
    CLK_counter = CLK_counter+1;
    
    if (CLK_counter >= 100) begin
        CLK_counter <= 0;
        P1A8 = ~P1A8;
    end
    
end

endmodule
