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