module SignExtension(a, result);
    input [15:0] a; // 16-bit input
    output reg [31:0] result; // 32-bit output Note: this would run if I didnt make this a register

    always @* begin
        if (a[15] == 1'b0) begin
            assign result = {16'b0000000000000000, a};
        end else begin
            assign result = {16'b1111111111111111, a};
        end
    end
endmodule


//Gonna write the test module in here
module test_sign_extension;
    reg [15:0]a;
    wire [31:0]result;
    //Instantiate sign extender
    SignExtension extender(
        .a(a),
        .result(result)
    );

    //Begin tests
    initial begin
        $monitor("a = %b | result = %b", a, result);

        //Test 1: Extend positive
        a = 16'b0000000000000001;
        #10;
        $display("Extension: a = %b | result = %b", a, result);

        //Test 2: Extend Negative
        a = 16'b1111111111111111;
        #10;
        $display("Extension: a = %b | result = %b", a, result);

        $finish;
    end
endmodule