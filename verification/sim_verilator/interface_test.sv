interface Test_if();
   bit a, b;

   modport tm(output  a);

endinterface

module Test1(Test_if i);
endmodule

module Top;
   Test_if t_if();


   Test1 t(.i(t_if));

endmodule
