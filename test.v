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

module OneBitALU(a, b, cin, less, op, result, cout, g, p, set);
  input a, b, cin; // Inputs to the one-bit ALU, "cin" is the carry-in bit.
  input [2:0] op; // 3-bit operation code. op[2] is the "binv". op[0] is the
  
  // least significant bit.
  input less; // This input will be set as 0 for all ALUs but the one corresponding to the most-significant bit.
  output result; // The result of the ALU (depends on the operation that is chosen)
  output cout; // Carry out bit of the adder
  output g, p; // Generate and propagate signals that are to be used by the CLA unit.
  output set; // This is the "sum" output of the full-adder.

  wire b_inverted;  // Output wires for each possible operation
  wire sum;
  wire and_result, or_result, slt_result; 
  wire carry;
  
  //Check if b needs to be inverted
  assign b_inverted = op[2] ? ~b : b;
    
  //Adder logic
  assign {cout, sum} = a + b_inverted + cin;
  
  //Compute results for other possible operations
  assign and_result = a & b_inverted;
  assign or_result = a | b_inverted;
  assign slt_result = less;
  assign carry = a & b_inverted | (a | b_inverted) & cin;
   
  //Determine generate and propogate signals for CLA
  assign g = and_result;
  assign p = or_result;

  //assigns
  assign set = sum;
  assign cout = carry;
  //Determine desired operation and return the results
  assign result = (op[1:0] == 2'b00) ? and_result :
                  (op[1:0] == 2'b01) ? or_result :
                  (op[1:0] == 2'b10) ? sum :
                  slt_result;
endmodule//OneBitALU


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


module FourBitALU(a, b, op, result, less, cin, cout, G, P, set, zero, overflow);
    input [3:0] a, b; // Inputs to the one-bit ALU.
    input [2:0] op; // 3-bit operation code. op[2] is the "binv". op[0] is the least significant bit.
    input cin; // carry in
    input less;
    output [3:0] result; // The result of the ALU (depends on the operation that is chosen)
    output cout; // Carry-out bit of the ALU
    output G, P; // Block generate and propagate of the four-bit ALU
    output set; // This is the set output of the most significant ALU block
    output zero; // if zero
    output overflow; // This bit indicates that an overflow has occurred. (Ignores what operation is chosen for ALU)
    
    //Create some wires for the operations
    wire cout0, cout1, cout2;
    wire G0, G1, G2, G3;
    wire P0, P1, P2, P3;
    wire [3:0] sets; //Wires used to retrieve the output of set from each ALU
    
    wire initial_cin = op[2] ? 1'b1 : cin;

    //Implement Carry Look Ahead Logic
    CLA carry_lookahead(.g0(G0), .p0(P0), .g1(G1), .p1(P1), .g2(G2), .p2(P2), .g3(G3), .p3(P3), .cin(initial_cin), .C1(cout0), .C2(cout1), .C3(cout2), .C4(cout), .G(G), .P(P)); 
    
    //Declare a ALU for each bit
    OneBitALU alu0(.a(a[0]), .b(b[0]), .cin(initial_cin), .less(less), .op(op), .result(result[0]), .cout(cout0), .g(G0), .p(P0), .set(sets[0]));
    OneBitALU alu1(.a(a[1]), .b(b[1]), .cin(cout0),       .less(1'b0), .op(op), .result(result[1]), .cout(cout1), .g(G1), .p(P1), .set(sets[1]));
    OneBitALU alu2(.a(a[2]), .b(b[2]), .cin(cout1),       .less(1'b0), .op(op), .result(result[2]), .cout(cout2), .g(G2), .p(P2), .set(sets[2]));
    OneBitALU alu3(.a(a[3]), .b(b[3]), .cin(cout2),       .less(1'b0), .op(op), .result(result[3]), .cout(cout), .g(G3), .p(P3), .set(sets[3]));
    
    assign set = sets[3]; // assign msb
    assign zero = (result == 4'h0); // set zero if all result bits are 0

    //Implement overflow detector
    OverflowDetection flag(.cin(cout2), .cout(cout), .result(result[3]), .op(op), .overflow(overflow));
endmodule // FourBitALU


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

  // Handle the "less" flag
  assign b_muxed = op[2] ? ~b : b; // Invert b for subtraction (two's complement)

  // Implement Carry Look Ahead Logic
  CLA carry_lookahead(.g0(G0), .p0(P0), .g1(G1), .p1(P1), .g2(G2), .p2(P2), .g3(G3), .p3(P3), 
                       .cin(cin), .C1(C1), .C2(C2), .C3(C3), .C4(C4), .G(g), .P(p)); 
  
  // Instantiate FourBitALUs
  FourBitALU alu0(.a(a[3:0]),   .b(b_muxed[3:0]),   .op(op), .result(result0), .less(less), .cin(cin), .cout(C1), .G(G0), .P(P0), .set(set0), .overflow(overflow0)); 
  FourBitALU alu1(.a(a[7:4]),   .b(b_muxed[7:4]),   .op(op), .result(result1), .less(1'b0), .cin(C1),  .cout(C2), .G(G1), .P(P1), .set(set1), .overflow(overflow1));
  FourBitALU alu2(.a(a[11:8]),  .b(b_muxed[11:8]),  .op(op), .result(result2), .less(1'b0), .cin(C2),  .cout(C3), .G(G2), .P(P2), .set(set2), .overflow(overflow2));
  FourBitALU alu3(.a(a[15:12]), .b(b_muxed[15:12]), .op(op), .result(result3), .less(1'b0), .cin(C3),  .cout(C4), .G(G3), .P(P3), .set(set3), .overflow(overflow3));

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

//32 bit ALU module
module ALU32bit(a, b, op, result, set, zero, overflow);
    input [31:0] a, b;
    input [2:0] op; // op[2] is "binv". op[1:0] denotes the 2-bit operation.
    output [31:0] result;
    output set; // set is the result of the most-significant ADDER unit.
    output zero; // zero is 1 if the result is 0x0000. Otherwise, it is 0.
    output overflow;
    wire cout0; //carry out from alu0
    wire cout1; //carry out of the upper 16 bits
    wire [15:0]result0; //Results from each 16 bit individually
    wire [15:0]result1;
    wire zero0; //zero output from alu0
    wire zero1; //zero output from alu1
    wire set1; //set from the upper 16 bit alu

    ALU16bit alu0(.a(a[15:0]), .b(b[15:0]), .cin(op[2]), .less(set1), .op(op[2:0]), .result(result0), .cout(cout0), .zero(zero0));
    ALU16bit alu1(.a(a[31:16]), .b(b[31:16]), .cin(cout0), .less(1'b0), .op(op[2:0]), .result(result1), .cout(cout1), .set(set1), .zero(zero1));

    assign result = {result1, result0}; //Combine 16 bit ALU results
    assign set = set1;                  //Calculate set
    assign zero = zero0 & zero1;        // Calculate zero
    assign overflow = zero & 1'b0;      //Detect if there is overflow
endmodule