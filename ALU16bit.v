module ALU16bit(a, b, cin, less, op, result, cout, set, zero, g, p, overflow);
  // Inputs
  input [15:0] a, b;
  input cin, less;
  input [2:0] op; // op[2] is "binv". op[1:0] denotes the 2-bit operation.

  // Outputs
  output [15:0] result;
  output cout, set, zero, g, p, overflow; // set is the result of the most-significant ADDER unit.
  
  // Internal wires
  wire C1, C2, C3, C4;
  wire G0, G1, G2, G3;
  wire P0, P1, P2, P3;
  wire [3:0] result0, result1, result2, result3; // Results from each ALU
  wire zero0, zero1, zero2, zero3; // Zero flags from each ALU
  wire overflow0, overflow1, overflow2, overflow3;
  wire set0, set1, set2, set3;
  wire [15:0] b_muxed; // Used to invert b if necessary for subtraction

  // Determine if we are subtracting
  wire subtractionBit = op[2]; // Use op[2] directly for clarity
  wire initial_cin = (subtractionBit) ? 1'b1 : cin; // Set the initial carry-in

  assign b_muxed = (subtractionBit) ? ~b : b; // Invert b for subtraction (two's complement)

  // Implement Carry Look Ahead Logic
  CLA carry_lookahead(.g0(G0), .p0(P0), .g1(G1), .p1(P1), .g2(G2), .p2(P2), .g3(G3), .p3(P3), .cin(initial_cin), .C1(C1), .C2(C2), .C3(C3), .C4(C4), .G(g), .P(p)); 
  
  // Instantiate FourBitALUs
  FourBitALU alu0(.a(a[3:0]),   .b(b_muxed[3:0]),   .op(op), .result(result0), .less(less), .cin(initial_cin), .cout(C1), .G(G0), .P(P0), .set(set0), .overflow(overflow0)); 
  FourBitALU alu1(.a(a[7:4]),   .b(b_muxed[7:4]),   .op(op), .result(result1), .less(1'b0), .cin(C1),          .cout(C2), .G(G1), .P(P1), .set(set1), .overflow(overflow1));
  FourBitALU alu2(.a(a[11:8]),  .b(b_muxed[11:8]),  .op(op), .result(result2), .less(1'b0), .cin(C2),          .cout(C3), .G(G2), .P(P2), .set(set2), .overflow(overflow2));
  FourBitALU alu3(.a(a[15:12]), .b(b_muxed[15:12]), .op(op), .result(result3), .less(1'b0), .cin(C3),          .cout(C4), .G(G3), .P(P3), .set(set3), .overflow(overflow3));

  // Detect overflow
  OverflowDetection flag(.cin(C3), .cout(C4), .result(result3[3]), .op(op), .overflow(overflow));

  // Calculate zero
  assign zero0 = (result0 == 4'b0000) ? 1 : 0;
  assign zero1 = (result1 == 4'b0000) ? 1 : 0;
  assign zero2 = (result2 == 4'b0000) ? 1 : 0;
  assign zero3 = (result3 == 4'b0000) ? 1 : 0;
  assign zero = zero0 & zero1 & zero2 & zero3;

  // Combine results
  assign result = (op[2] && result3[3] == 1) ? ~{result3, result2, result1, result0} : {result3, result2, result1, result0}; // Directly combine results
  assign cout = C4; // Connect the final carry-out
endmodule // ALU16bit