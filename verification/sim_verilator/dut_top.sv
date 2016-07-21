import Pu_types::*;

module dut_top(
           input clk,
           input reset
);
   localparam IMEM_ADDR_WIDTH = 13;
   localparam DMEM_ADDR_WIDTH = 13;
   localparam IMEM_SIZE = 2**IMEM_ADDR_WIDTH;
   localparam DMEM_SIZE = 2**DMEM_ADDR_WIDTH;

   Pu_ctrl_if           ctrl_if();
   Timer_if             timer_if();

   Ram_if #(.ADDR_WIDTH(IMEM_ADDR_WIDTH)) imem_if();
   Ram_if  #(.ADDR_WIDTH(DMEM_ADDR_WIDTH)) dmem_if();
   Ram_if #(.ADDR_WIDTH(IMEM_ADDR_WIDTH)) dummy_imem_if();
   Ram_if  #(.ADDR_WIDTH(DMEM_ADDR_WIDTH)) dummy_dmem_if();

   // TODO(Christian): Adjust to correct width
   Bus_if  dmem_bus_if(.Clk(clk));
   Bus_if iobus_if(.Clk(clk));
   Bus_if vector_bus_if(.Clk(clk));
   Bus_if vector_pbus_if(.Clk(clk));
   Syn_io_if        syn_io_a_if();
   Syn_io_if        syn_io_b_if();

   Pu_types::Word   gout;
   Pu_types::Word   gin;
   Pu_types::Word   goe;


   Pu_v2 #(
           .OPT_BCACHE(0),
           .OPT_MULTIPLIER(1'b0),
           .OPT_DIVIDER(1'b0),
           .OPT_VECTOR(1'b0),
           .OPT_NEVER(1'b0),
           .OPT_SYNAPSE(1'b0),
           .OPT_IOBUS(1'b0),
           .OPT_DMEM(MEM_TIGHT),
           .OPT_IF_LATENCY(1),
           .OPT_BCACHE_IGNORES_JUMPS(1'b1),
           .OPT_WRITE_THROUGH(1'b1),
           .OPT_LOOKUP_CACHE(1'b1)
           )
   pu
     (
      .clk(clk),
      .reset(reset),
      .hold(pu_hold),
      .imem(imem_if),
      .dmem(dmem_if),
      .dmem_bus(dmem_bus_if),
      .vector_bus(vector_bus_if),
      .vector_pbus(vector_pbus_if),
      .iobus(iobus_if),
      .gout(gout),
      .gin(gin),
      .goe(goe),

      .ctrl(ctrl_if),
      .timer(timer_if),

      .syn_io_a(syn_io_a_if),
      .syn_io_b(syn_io_b_if)
      );

   L1_memory #( .IS_DUALPORT(1'b0), .ADDR_WIDTH(IMEM_ADDR_WIDTH))
   imem ( .clk(clk), .reset(reset), .intf(imem_if), .intf2(dummy_imem_if));

   L1_memory #( .IS_DUALPORT(1'b0), .ADDR_WIDTH(DMEM_ADDR_WIDTH))
   dmem (.clk(clk), .reset(reset), .intf(dmem_if), .intf2(dummy_dmem_if));


   Timer_unit
   timer (.clk(clk), .reset(reset), .intf(timer_if));


endmodule
