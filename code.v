module CLA(g0, p0, g1, p1, g2, p2, g3, p3, cin, C1, C2, C3, C4, G, P);
  input g0, p0, g1, p1, g2, p2, g3, p3; // Generate and propagate signals corresponding to each bit.
  input cin; // Carry-in input
  output C1, C2, C3, C4; // Carry bits computed by the CLA.
  output G, P; // Block generate and block propagate to be used by CLAs at higher level.

  assign G = g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & g0);
  assign P = p3 & p2 & p1 & p0;
  assign C1 = g0 | (p0 & cin);
  assign C2 = g1 | (p1 & g0) | (p1 & p0 & cin);
  assign C3 = g2 | (p2 & g1) | (p2 & p1 & g0) | (p2 & p1 & p0 & cin);
  assign C4 = g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & g0) | (p3 & p2 & p1 & p0 & cin);
endmodule//CLA



module OneBitALU(a, b, cin, less, op, result, cout, g, p, set);
  input a, b, cin; // Inputs to the one-bit ALU, "cin" is the carry-in bit.
  input [2:0] op; // 3-bit operation code. op[2] is the "binv". op[0] is the
  
  // least significant bit.
  input less; // This input will be set as 0 for all ALUs but the one
  
  //corresponding to the most-significant bit.
  output result; // The result of the ALU (depends on the operation that is
  
  // chosen)
  output cout; // Carry out bit of the adder
  output g, p; // Generate and propagate signals that are to be used by the
  
  // CLA unit.
  output set; // This is the "sum" output of the full-adder.

  wire b_inverted;  // Output wires for each possible operation
  wire sum;
  wire and_res, or_res, slt_res; 
  wire carry;
  
  //Check if b needs to be inverted
  assign b_inverted = op[2] ? ~b : b;
    
  //Adder logic
  assign {cout, sum} = a + b_inverted + cin;
  
  //Compute results for other possible operations
  assign and_res = a & b;
  assign or_res = a | b;
  assign slt_res = less;
  assign carry = a & b_inverted | (a | b_inverted) & cin;
   
  //Determine generate and propogate signals for CLA
  assign g = a & b_inverted;
  assign p = a ^ b_inverted;

  //assigns
  assign set = sum;
  assign cout = carry;
  assign g = and_res;
  assign p = or_res;
  //Determine desired operation and return the results
  assign result = (op[1:0] == 2'b00) ? and_res :
                  (op[1:0] == 2'b01) ? or_res :
                  (op[1:0] == 2'b10) ? sum :
                  slt_res;
endmodule//OneBitALU



//Next up is to design the overflow detection module
module OverflowDetection(cin, cout, result, op, overflow);
  input cin, cout;	//Inputs from last ALU operation needed to determine overflow (MSB operation)
  input result;
  input [2:0] op;
  output overflow;	//flag to be returned that indicates an oveflow
  
  //assign overflow = cin ^ cout;	//overflow occurs with different carry in and out values for MSB
  assign overflow = (op[1:0] == 2'b10) && (
    // Addition overflow check
    (op[2] == 0 && ((cin == 0 && cout == 0 && result == 1) || (cin == 1 && cout == 1 && result == 0))) ||
    // Subtraction overflow check
    (op[2] == 1 && ((cin == 0 && cout == 1 && result == 1) || (cin == 1 && cout == 0 && result == 0)))
  );
endmodule//OverflowDetection



module FourBitALU(a, b, op, result, less, cin, cout, G, P, set, zero, overflow);
  input [3:0] a, b; // Inputs to the one-bit ALU.
  input [2:0] op; // 3-bit operation code. op[2] is the "binv". op[0] is 							the least significant bit.
  input cin; // carry in
  input less;
  output [3:0] result; // The result of the ALU (depends on the operation that is chosen)
  output cout; // Carry-out bit of the ALU
  output G, P; // Block generate and propagate of the four-bit ALU
  output set; // This is the set output of the most significant ALU block
  output zero; // if zero
  output overflow; // This bit indicates that an overflow has occurred. (Ignores what operation is chosen for ALU)
  
  //Create some wires for the operations
  wire cout0, cout1, cout2, cout3;
  wire G0, G1, G2, G3;
  wire P0, P1, P2, P3;
  wire [3:0] sets; //Wires used to retrieve the output of set from each ALU
  
  
  //Implement Carry Look Ahead Logic
  CLA carry_lookahead(.g0(G0), .p0(P0), .g1(G1), .p1(P1), .g2(G2), .p2(P2), .g3(G3), .p3(P3), .cin(cin), .C1(cout0), .C2(cout1), .C3(cout2), .C4(cout), .G(G), .P(P)); 
  
  //Declare a ALU for each bit
  OneBitALU alu0(.a(a[0]), .b(b[0]), .cin(cin), .less(less), .op(op), .result(result[0]), .cout(), .g(G0), .p(P0), .set(sets[0]));
  OneBitALU alu1(.a(a[1]), .b(b[1]), .cin(cout0), .less(1'b0), .op(op), .result(result[1]), .cout(), .g(G1), .p(P1), .set(sets[1]));
  OneBitALU alu2(.a(a[2]), .b(b[2]), .cin(cout1), .less(1'b0), .op(op), .result(result[2]), .cout(), .g(G2), .p(P2), .set(sets[2]));
  OneBitALU alu3(.a(a[3]), .b(b[3]), .cin(cout2), .less(1'b0), .op(op), .result(result[3]), .cout(), .g(G3), .p(P3), .set(sets[3]));
  
  assign set = sets[3];// assign msb
  assign zero = (sets == 4'h0); // set zero if all sets are 0

  //Implement overflow detector
  OverflowDetection flag(.cin(cout2), .cout(cout), .result(result[3]), .op(op), .overflow(overflow));
endmodule//FourBitALU



module ALU16bit(a, b, cin, less, op, result, cout, set, zero, g, p, overflow);
  //Make inputs
  input [15:0] a, b;
  input cin, less;
  input [2:0] op; // op[2] is "binv". op[1:0] denotes the 2-bit operation.
  ///////////////////////////////
  
  //make outputs
  output [15:0] result;
  output cout, set, zero, g, p, overflow;// set is the result of the most-significant ADDER unit.
                                         // zero is 1 if the result is 0x0000. Otherwise, it is 0.
  ///////////////////////////////

  //Create wires
  wire C1, C2, C3, C4;
  wire G0, G1, G2, G3;
  wire P0, P1, P2, P3;
  wire [3:0] result0, result1, result2, result3; //used to store results from each alu
  wire zero0, zero1, zero2, zero3; //used to store zero from each alu
  wire overflow0, overflow1, overflow2, overflow3;
  wire set0, set1, set2, set3;
  wire [15:0] b_muxed; // Used to invert b if necessary for subtraction
  wire [31:0] combinedResults; //used to combine results of all ALUs
  wire subtractionBit = (op == 3'b110) ? 1 : 0;

  // Set the initial carry-in (cin) to 1 for subtraction, 0 for addition
  wire initial_cin = ((subtractionBit == 1) ? 1'b1 : cin); // For subtraction, cin should be 1
  ///////////////////////////////


  // Handle the "less" flag
  // When less is 1, we perform a subtraction, i.e., a - b
  // To do this, we can use the binv bit (invert b) and set cin for the last addition
  assign b_muxed = subtractionBit ? ~b : b; // If subtractionBit is 1, invert b for subtraction (two's complement)

  //Implement Carry Look Ahead Logic
  CLA carry_lookahead(.g0(G0), .p0(P0), .g1(G1), .p1(P1), .g2(G2), .p2(P2), .g3(G3), .p3(P3), .cin(initial_cin), .C1(C1), .C2(C2), .C3(C3), .C4(C4), .G(g), .P(p)); 
  
  FourBitALU alu0(.a(a[3:0]),   .b(b_muxed[3:0]),   .op(op), .result(result0), .less(less), .cin(initial_cin), .cout(C1), .G(G0), .P(P0), .set(set0), .overflow(overflow0)); 
  FourBitALU alu1(.a(a[7:4]),   .b(b_muxed[7:4]),   .op(op), .result(result1), .less(1'b0), .cin(C1),          .cout(C2), .G(G1), .P(P1), .set(set1), .overflow(overflow1));
  FourBitALU alu2(.a(a[11:8]),  .b(b_muxed[11:8]),  .op(op), .result(result2), .less(1'b0), .cin(C2),          .cout(C3), .G(G2), .P(P2), .set(set2), .overflow(overflow2));
  FourBitALU alu3(.a(a[15:12]), .b(b_muxed[15:12]), .op(op), .result(result3), .less(1'b0), .cin(C3),          .cout(C4), .G(G3), .P(P3), .set(set3), .overflow(overflow3));
  ///////////////////////////////

  //detect overflow
  OverflowDetection flag(.cin(C3), .cout(C4), .result(result3[3]), .op(op), .overflow(overflow));
  ///////////////////////////////

  //Calculate zero
  assign zero0 = (result0 == 4'b0000) ? 1 : 0;
  assign zero1 = (result1 == 4'b0000) ? 1 : 0;
  assign zero2 = (result2 == 4'b0000) ? 1 : 0;
  assign zero3 = (result3 == 4'b0000) ? 1 : 0;
  assign zero = zero0 & zero1 & zero2 & zero3;
  ///////////////////////////////

  //Combine results
  assign combinedResults = {result3, result2, result1, result0};
  assign result = ((result3[3] == 1) ? ~combinedResults: combinedResults);
  ///////////////////////////////
endmodule//ALU16bit
