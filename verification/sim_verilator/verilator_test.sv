

package test_0;
   function automatic logic[2:0] cr_idx_encode;
      input logic [7:0] sel;
      logic [2:0]       rv;
      case(sel)
        8'b00000001: rv = 3'h0;
        8'b00000010: rv = 3'h1;
        8'b00000100: rv = 3'h2;
        8'b00001000: rv = 3'h3;
        8'b00010000: rv = 3'h4;
        8'b00100000: rv = 3'h5;
        8'b01000000: rv = 3'h6;
        8'b10000000: rv = 3'h7;
        default:     rv = 3'hx;
      endcase

      return rv;
   endfunction
endpackage

module test_1;
   bit [2:0] out;
   assign out = test_0::cr_idx_encode(8'b00001000);
endmodule
