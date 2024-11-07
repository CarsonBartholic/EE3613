module FourBitALU(a, b, op, result, less, cin, cout, G, P, set, zero, overflow);
    input [3:0] a, b; // input values
    input [2:0] op; // op code
    input cin;// carry in
    input less;
    output [3:0] result;
    output cout; // carry out
    output G, P;
    output set;
    output zero;
    output overflow;
    
    wire cout0, cout1, cout2;
    wire G0, G1, G2, G3;
    wire P0, P1, P2, P3;
    wire [3:0] sets;
    
    wire initial_cin = op[2] ? 1'b1 : cin;

    // Implement Carry Look Ahead Logic
    CLA carry_lookahead(.g0(G0), .p0(P0), .g1(G1), .p1(P1), .g2(G2), .p2(P2), .g3(G3), .p3(P3), 
                        .cin(initial_cin), .C1(cout0), .C2(cout1), .C3(cout2), .C4(cout), .G(G), .P(P)); 
    
    // Declare an ALU for each bit
    OneBitALU alu0(.a(a[0]), .b(b[0]), .cin(initial_cin), .less(less), .op(op), .result(result[0]), .cout(cout0), .g(G0), .p(P0), .set(sets[0]));
    OneBitALU alu1(.a(a[1]), .b(b[1]), .cin(cout0),       .less(1'b0), .op(op), .result(result[1]), .cout(cout1), .g(G1), .p(P1), .set(sets[1]));
    OneBitALU alu2(.a(a[2]), .b(b[2]), .cin(cout1),       .less(1'b0), .op(op), .result(result[2]), .cout(cout2), .g(G2), .p(P2), .set(sets[2]));
    OneBitALU alu3(.a(a[3]), .b(b[3]), .cin(cout2),       .less(1'b0), .op(op), .result(result[3]), .cout(cout), .g(G3), .p(P3), .set(sets[3]));
    
    assign set = sets[3]; // assign msb
    assign zero = (result == 4'h0); // set zero if all result bits are 0

    // Implement overflow detector
    OverflowDetection flag(.cin(cout2), .cout(cout), .result(result[3]), .op(op), .overflow(overflow));
endmodule
