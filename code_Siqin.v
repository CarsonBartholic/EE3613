// Code your design here
module FourBitALU(a, b, op, result, cin, cout, G, P, set, overflow);
    input [3:0] a, b;     // 4-bit inputs
    input [2:0] op;       // 3-bit operation code; op[2] is the "binv" for b (bitwise negation).
 	input cin;
  	output [3:0] result;  // 4-bit result of the ALU operation
    output cout;          // Carry-out of the 4-bit ALU
    output G, P;          // Block generate and propagate signals
    output set;           // Sum output (set) of the most significant bit (MSB)
    output overflow;      // Overflow flag for two's complement addition/subtraction

    wire [3:0] C;         // Carry signals between 1-bit ALUs
    wire [3:0] g, p;      // Generate and propagate signals for each bit
    wire [3:0] setv;      // Sum outputs from each 1-bit ALU
    wire C1, C2, C3, C4;  // Internal carry signals from the CLA

    // Instantiate four 1-bit ALUs
    // The least significant ALU takes "setv[3]" as the "less" input for comparison operations
  	OneBitALU OneBitALU0(a[0], b[0], cin, setv[3], op, result[0], C[0], g[0], p[0], setv[0]);
    OneBitALU OneBitALU1(a[1], b[1], C1, 1'b0, op, result[1], C[1], g[1], p[1], setv[1]);
    OneBitALU OneBitALU2(a[2], b[2], C2, 1'b0, op, result[2], C[2], g[2], p[2], setv[2]);
    OneBitALU OneBitALU3(a[3], b[3], C3, 1'b0, op, result[3], C[3], g[3], p[3], setv[3]);
  
    // Instantiate the Carry Look-Ahead (CLA) module for fast carry calculation
    CLA CLA_module0(g[0], p[0], g[1], p[1], g[2], p[2], g[3], p[3], op[2], C1, C2, C3, C4, G, P);
  
    // Instantiate the OverflowDetection module for the MSB (a[3], b[3])
    OverflowDetection OverflowDetection1(C3, C4, overflow);

    // Assign the final outputs
    assign set = setv[3];    // Set output from the MSB for comparison
    assign cout = C4;        // Carry-out from the 4-bit ALU
endmodule

module OneBitALU(a, b, cin, less, op, result, cout, g, p, set);
    input a, b, cin;      // Inputs to the one-bit ALU, "cin" is the carry-in bit.
    input [2:0] op;       // 3-bit operation code; op[2] is the "binv".
    input less;           // Less input, set to 0 for all ALUs except the most significant bit.
    
    output result;        // Result of the ALU operation.
    output cout;          // Carry-out bit.
    output g, p;          // Generate and propagate signals for CLA.
    output set;           // Sum output of the full adder.
  
    reg result, cout, g, p, set;
    wire bcomp;
  
      // Determine the value of bcomp based on the operation code
	assign bcomp = op[2] ? ~b : b;
  
    always @(a or b or op or cin or less)
      	begin
        	// Compute the sum and carry-out for addition
            set = (a ^ bcomp ^ cin);       // Sum output of the full-adder
            cout = (a & bcomp) | (cin & (a ^ bcomp));  // Carry-out

            // Generate and propagate signals for CLA
            g = a & bcomp;
            p = a | bcomp;

            // Select result based on operation code
            case (op)
                3'b000: result = a & bcomp;     // AND operation
                3'b001: result = a | bcomp;     // OR operation
                3'b010: result = set;           // Addition (set is sum output)
                3'b110: result = set;           // Subtraction (similar to addition with bcomp)
                3'b111: result = less;          // Less operation
                default: result = 0;
            endcase
    	end
endmodule

// Code your design here
module CLA(g0, p0, g1, p1, g2, p2, g3, p3, cin, C1, C2, C3, C4, G, P);
  input g0, p0, g1, p1, g2, p2, g3, p3;  // Generate and propagate signals corresponding to each bit. 
  input cin; // Carry-in input
  output C1, C2, C3, C4; // Carry bits computed by the CLA.  
  output G, P; // Block generate and block propagate to be used by CLAs at a higher level.

  // Use continuous assignment for combinational logic
  assign C1 = g0 | (p0 & cin);
  assign C2 = g1 | (p1 & C1);
  assign C3 = g2 | (p2 & C2);
  assign C4 = g3 | (p3 & C3);

  assign G = g3 | (g2 & p3) | (g1 & p3 & p2) | (g0 & p3 & p2 & p1);
  assign P = p3 & p2 & p1 & p0;
endmodule

module OverflowDetection(c0, c1, V);
    input c0;     // Carry-in to the most significant bit (MSB)
    input c1;     // Carry-out from the most significant bit (MSB)
    output V;     // Overflow flag, set to 1 if an overflow occurs

    // Overflow occurs in two's complement arithmetic when the carry-in 
    // and carry-out of the MSB differ. This indicates a result that 
    // cannot be represented in the fixed number of bits available.
    // V = 1 (overflow) when c0 and c1 are different (XOR operation).

    assign V = c0 ^ c1;  // Set overflow flag based on XOR of carry-in and carry-out
endmodule



module ALU16bit(a, b, cin, less, op, result, cout, set, zero, g, p, overflow);
  input [15:0] a, b;
  input cin, less;
  input [2:0] op; // op[2] is "binv". op[1:0] denotes the 2-bit operation.
  output [15:0] result;
  output cout, set, zero, g, p, overflow;
          // set is the result of the most-significant
          // ADDER unit. 
          // zero is 1 if the result is 0x0000. Otherwise, it is 0.

  wire cout0, cout1, cout2, cout3;
  wire G0, G1, G2, G3;
  wire P0, P1, P2, P3;
  wire [3:0] result0, result1, result2, result3; //used to store results from each alu
  wire zero0, zero1, zero2, zero3; //used to store zero from each alu
  wire overflow0, overflow1, overflow2, overflow3;
  wire set0, set1, set2, set3;
  wire [15:0] b_muxed; // Used to invert b if necessary for subtraction

  wire subtractionBit = op ? 3'b110 : 0;
  // Set the initial carry-in (cin) to 1 for subtraction, 0 for addition
  wire initial_cin = subtractionBit ? 1'b1 : cin; // For subtraction, cin should be 1

  // Handle the "less" flag
  // When less is 1, we perform a subtraction, i.e., a - b
  // To do this, we can use the binv bit (invert b) and set cin for the last addition
  assign b_muxed = less ? ~b : b; // If less is 1, invert b for subtraction (two's complement)

  FourBitALU alu0(.a(a[3:0]), .b(b_muxed[3:0]), .op(op), .result(result0), .cin(initial_cin), .cout(cout0), .G(G0), .P(P0), .set(set0), .overflow(overflow0)); 
  FourBitALU alu1(.a(a[7:4]), .b(b_muxed[7:4]), .op(op), .result(result1), .cin(cout0), .cout(cout1), .G(G1), .P(P1), .set(set1), .overflow(overflow1));
  FourBitALU alu2(.a(a[11:8]), .b(b_muxed[11:8]), .op(op), .result(result2), .cin(cout1), .cout(cout2), .G(G2), .P(P2), .set(set2), .overflow(overflow2));
  FourBitALU alu3(.a(a[15:12]), .b(b_muxed[15:12]), .op(op), .result(result3), .cin(cout2), .cout(cout),.G(G3), .P(P3), .set(set3), .overflow(overflow3));

  //Implement Carry Look Ahead Logic
  CLA carry_lookahead(.g0(G0), .p0(P0), .g1(G1), .p1(P1), .g2(G2), .p2(P2), .g3(G3), .p3(P3), .cin(cin), .C1(cout0), .C2(cout1), .C3(cout2), .C4(cout3), .G(g), .P(p)); 

  //Calculate zero
  assign zero0 = (result0 == 4'b0000) ? 1 : 0;
  assign zero1 = (result1 == 4'b0000) ? 1 : 0;
  assign zero2 = (result2 == 4'b0000) ? 1 : 0;
  assign zero3 = (result3 == 4'b0000) ? 1 : 0;
  assign zero = zero0 & zero1 & zero2 & zero3;
  ///////////////////////////////

  //Combine results
  assign result = {result3, result2, result1, result0};
  ///////////////////////////////
endmodule//ALU16bit
