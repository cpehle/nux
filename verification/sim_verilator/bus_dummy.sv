module Iobus_dummy
  #(parameter int RD_ACCEPT_LATENCY = 0,
    parameter int                    WR_ACCEPT_LATENCY = 0,
    parameter int                    RD_RETURN_LATENCY = 1,
    parameter int                    WR_RETURN_LATENCY = 1,
    parameter int                    RESPONSE_FUNCTION = 0, // 0 - STATIC return a static 32'h1
    // 1 - MEM return what was previously written
    // 2 - ZERO return a static 32'h0
    // 3 - ADDR return address
    parameter int                    DATA_WIDTH = 32,
    parameter int                    ADDR_WIDTH = 32,
    parameter bit                    BYTE_ENABLED = 1'b0,
    parameter logic [DATA_WIDTH-1:0] MEM_DEFAULT = 'x)
   ( input logic clk, reset,
     Bus_if.slave iobus );


   always_ff @(posedge clk)
     iobus.SCmdAccept <= 1'b0;



endmodule
