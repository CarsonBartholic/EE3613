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