module testBench;
    reg [15:0] a, b;
    reg cin, less;
    reg [2:0] op;
    wire [15:0] result;
    wire cout, set, zero, g, p, overflow;

    // Instantiate the ALU16bit module
    ALU16bit uut (
        .a(a),
        .b(b),
        .cin(cin),
        .less(less),
        .op(op),
        .result(result),
        .cout(cout),
        .set(set),
        .zero(zero),
        .g(g),
        .p(p),
        .overflow(overflow)
    );

    initial begin
        $monitor("a = %b, b = %b, op = %b | result = %b, cout = %b, g = %b, p = %b, set = %b, overflow = %b", a, b, op, result, cout, g, p, set, overflow);

        // Test case 1: Addition
        a = 16'b0000000000000001; b = 16'b0000000000000001; cin = 0; less = 0; op = 3'b010;
        #10;
        $display("Addition: result = %h, cout = %b, zero = %b", result, cout, zero);

        // Test case 2: Subtraction
        a = 16'b0000000000000111; b = 16'b0000000000000011; cin = 1; less = 0; op = 3'b110;
        #10;
        $display("Subtraction: result = %h, cout = %b, zero = %b", result, cout, zero);

        // Test case 3: AND
        a = 16'b0000000000010111; b = 16'b0000000000000111; cin = 0; less = 0; op = 3'b000;
        #10;
        $display("AND: result = %h, cout = %b, zero = %b", result, cout, zero);

        // Test case 4: OR
        a = 16'b0000000000000101; b = 16'b0000000000001010; cin = 0; less = 0; op = 3'b001;
        #10;
        $display("OR: result = %h, cout = %b, zero = %b", result, cout, zero);
        
        $finish;
    end
endmodule