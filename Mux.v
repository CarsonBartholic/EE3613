module Mux32Bit2Tol (a, b, op, result);
    input [31:0] a, b; // 32-bit inputs
    input op; //one bit selection input
    output reg [31:0] result; //32-bit output
    always @ * begin
        if (op == 1'b0) begin
            result = a;
        end else begin
            result = b;
        end
    end
endmodule



module Mux5Bit2Tol (a, b, op, result);
    input [4:0] a, b; // 5-bit inputs
    input op; //one bit selection input
    output reg [4:0] result; // 5-bit output

    always @ * begin
        if (op == 1'b0) begin
            result = a;
        end else begin
            result = b;
        end
    end
endmodule