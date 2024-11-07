module mux32TestBench;
    reg [31:0] a, b;
    reg op;
    wire [31:0] result;
  
    // Instantiate the Mux32Bit2tol module
    Mux32Bit2Tol uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    initial begin
        $dumpfile("dump32bit.vcd"); $dumpvars;
        $monitor("a = %b, b = %b, op = %b | result = %b", a, b, op, result);

        // Test case 1: First Choice 32bit
        a = 32'b11111111111111111111111111111111; b = 32'b00000000000000000000000000000000; op = 1'b0;
        #10;
        $display("First Choice 32bit: result = %b", result);

        // Test case 2: First Choice 32bit
        a = 32'b00000000000000000000000000000000; b = 32'b00000000000000001111111111111111; op = 1'b0;
        #10;
        $display("First Choice 32bit: result = %b", result);

        // Test case 3: Second Choice 32bit
        a = 32'b10101010101010101010101010101010; b = 32'b01010101010101010101010101010101; op = 1'b1;
        #10;
        $display("Second Choice 32bit: result = %b", result);

        // Test case 4: Second Choice 32bit
        a = 32'b11111111110000000000101010101011; b = 32'b00000000000000001111111111111111; op = 1'b1;
        #10;
        $display("Second Choice 32bit: result = %b", result);
        
        $finish;
    end
endmodule


module mux5TestBench;
    reg [4:0] a, b;
    reg op;
    wire [4:0] result;
  
    // Instantiate the Mux5Bit2tol module
    Mux5Bit2Tol uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        $monitor("a = %b, b = %b, op = %b | result = %b", a, b, op, result);

        // Test case 1: First Choice 5bit
        a = 5'b00000; b = 5'b11111; op = 1'b0;
        #10;
        $display("First Choice 5bit: result = %b", result);

        // Test case 2: First Choice 5bit
        a = 5'b11000; b = 5'b00111; op = 1'b0;
        #10;
        $display("First Choice 5bit: result = %b", result);

        // Test case 3: Second Choice 5bit
        a = 5'b10101; b = 5'b11110; op = 1'b1;
        #10;
        $display("Second Choice 5bit: result = %b", result);

        // Test case 4: Second Choice 5bit
        a = 5'b01010; b = 5'b11001; op = 1'b1;
        #10;
        $display("Second Choice 5bit: result = %b", result);
        
        $finish;
    end
endmodule