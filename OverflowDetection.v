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