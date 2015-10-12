// Copyright 2015 Heidelberg University Copyright and related rights are
// licensed under the Solderpad Hardware License, Version 0.51 (the "License");
// you may not use this file except in compliance with the License. You may obtain
// a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
// required by applicable law or agreed to in writing, software, hardware and
// materials distributed under this License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
// the License for the specific language governing permissions and limitations
// under the License.


package Frontend;
  localparam int unsigned iaddr_width = 14;
  localparam int unsigned num_threads = 1;
  localparam int unsigned num_fubs = 9;

  localparam int unsigned mul_latency = 4;//8;//14; //8;/*designware*///6;/*xilinx mul d3*/
  localparam int unsigned div_latency = 31;//37; //28;
  localparam int unsigned ls_latency = 2; // allowed: 2,3
  localparam int unsigned ls_bus_latency = 3;//5;//7;   // expected latency when using the bus interface
                                                // does not modify latency -> don't change
  localparam int unsigned ls_bus_addr_latency = 2;  // latency for address updates when using the bus interface
  localparam int unsigned branch_latency = 1;  // does not modify latency -> don't change
  localparam int unsigned dev_ctrl_latency = 5;
  localparam int unsigned never_latency = 1;  // does not modify latency -> don't change
  localparam int unsigned synapse_latency = 1;
  //localparam int default_latency = 2; // allowed: 2,3
  localparam int unsigned default_latency = 1; // allowed: 2,3

  typedef logic[iaddr_width-1:0] Iaddr;
  typedef logic[0:0] Thread_id;

  /** Counter type for multi-cycle instructions. */
  typedef logic[4:0] Seq_ctr;

  /** Data generated by the frontend to issue an instruction. */
  typedef struct {
    Pu_inst::Inst ir;
    Pu_types::Address pc;
    Pu_types::Address npc;
    logic valid;
    Thread_id thread;
  } Issue_slot;

  typedef logic[$bits(Issue_slot)-1:0] Issue_slot_bits;
  typedef Issue_slot Issue_array[0:num_fubs-1];

  /** Signals to control control transfers. */
  typedef struct {
		/** Assert to initiate control transfer. */
    logic jump;
    /** Assert to indicate jump is transfer to ISR. */
    //logic int_jump;
		/** Target vector of control transfer. */
    Iaddr jump_vec;
		/** Assert to indicate that a certain instruction was a taken branch.*/
    logic fb_taken;
		/** Assert to indicate that a certain instruction was a not-taken
		* branch. */
    logic fb_not_taken;
		/** Iaddr of the branch instruction for that taken or not-taken is
		* indicated. */
    Iaddr fb_pc;
  } Branch_control;

  /** For now just a place-holder */
  typedef Branch_control Interrupt_control;

  /** General control signals for instruction fetch and issue. */
  typedef struct {
    logic interrupt;
    logic wakeup;
  } Frontend_control;

  /** Output from the instruction streaming unit indicating the current state
  * of instruction fetching. */
  typedef struct {
		/** Iaddr of the current instruction. */
    Iaddr pc;
		/** Iaddr of the next instruction. */
    Iaddr npc;
		/** Current instruction. */
    Pu_inst::Inst inst;
		/** The current instruction was predicted to be a taken branch. The
		* predicted target is presented at npc. */
    logic predicted_taken;
		/** Indicates validity of the current instruction. Is currently only
		* used after reset until the first instruction from memory is
		* available. It is not deasserted between jump and trans_cmplt. */
    logic valid;
		/** Indicates completion of a control transfer when high. */
    logic trans_cmplt;
  } Fetch_state;

  /** Control signals to clear tracking of completed instructions using
  * delayed write-back. */
  typedef struct {
    logic valid;
    Pu_types::Reg_index gpr;
  } Delayed_commit;

  /** Enumerate sets of functional units that are available in the system. To
  * each set an instruction can be issued separately. */
  typedef enum logic[8:0] {
    FUB_BRANCH     = 9'b0_0000_0001,
    FUB_FIXEDPOINT = 9'b0_0000_0010,
    FUB_LOAD_STORE = 9'b0_0000_0100,
    FUB_MUL_DIV    = 9'b0_0000_1000,
    FUB_DIV        = 9'b0_0001_0000,
    FUB_IO         = 9'b0_0010_0000,
    FUB_NEVER      = 9'b0_0100_0000,
    FUB_SYNAPSE    = 9'b0_1000_0000,
    FUB_VECTOR     = 9'b1_0000_0000,
    FUB_UNDEF      = 9'bx_xxxx_xxxx
  } Fu_set;

  typedef logic[Pu_types::clog2($bits(Fu_set)-1):0] Fu_set_id;

  localparam Fu_set_id FUB_ID_BRANCH = 0;
  localparam Fu_set_id FUB_ID_FIXEDPOINT = 1;
  localparam Fu_set_id FUB_ID_LOAD_STORE = 2;
  localparam Fu_set_id FUB_ID_MUL_DIV = 3;
  localparam Fu_set_id FUB_ID_DIV = 4;
  localparam Fu_set_id FUB_ID_IO = 5;
  localparam Fu_set_id FUB_ID_NEVER = 6;
  localparam Fu_set_id FUB_ID_SYNAPSE = 7;
  localparam Fu_set_id FUB_ID_VECTOR = 8;
  localparam int FUB_ID_END = 9;
  localparam Fu_set_id FUB_ID_UNDEF = 'x;

  typedef logic Fub_readies[0:num_fubs-1];

  //typedef logic[4:0] Inst_latency;  // with mul and div
  typedef logic[3:0] Inst_latency;  // with mul
  //typedef logic[1:0] Inst_latency;    // without mul and div
  typedef logic[2**$bits(Inst_latency)-1:0] Inst_latency_onehot;

  /** Select how the XER register is affected during writeback. */
  typedef enum logic[2:0] {
    XER_ZERO       = 3'b000,
    XER_DEST_ALL   = 3'b001,   /**< Write everything */
    XER_DEST_CA    = 3'b010,   /**< Record carry */
    XER_DEST_OV    = 3'b100,   /**< Record OV and SO bits */
    XER_DEST_CA_OV = 3'b110
  } Xer_dest;

  typedef logic[$bits(Xer_dest)-1:0] Xer_dest_bits;


  /** Tag used to track instructions with non-deterministic latency */
  typedef logic[0:0] Track_tag;

  /** Control signals generated in the pre-decode stage. */
  typedef struct {
    logic read_ra;
    logic read_rb;
    logic read_rt;
    logic write_ra;
    logic write_rt;
    Pu_types::Reg_index ra;
    Pu_types::Reg_index rb;
    Pu_types::Reg_index rt;
    logic b_immediate;   /**< Operand b is immediate. */

    logic read_ctr;
    logic write_ctr;
    logic read_lnk;
    logic write_lnk;
    logic[7:0] write_cr;
    logic[7:0] read_cr_0;
    logic[7:0] read_cr_1;
    logic[7:0] read_cr_2;
    logic read_xer;
    logic write_xer;
    Xer_dest xer_dest;
    logic read_spr;
    logic read_spr2;
    Pu_types::Spr_reduced spr;
    Pu_types::Spr_reduced spr2;
    logic write_spr;
    Pu_types::Spr_reduced spr_dest;
    logic write_mem;
    logic read_msr;
    logic write_msr;
    logic write_nve;

    Fu_set fu_set;        /**< Instruction belongs to this set of functional units. */
    logic context_sync;   /**< Instruction is context synchronizing. */
    logic mem_bar;        /**< Instruction is a memory barrier. (also used for synswp instruction) */
    logic halt;           /**< Instruction causes a processor halt. */
    logic nd_latency;     /**< Instruction has non-deterministic delay. */
    Inst_latency latency; /**< Number of cycles until write-back of this instruction. */
    Seq_ctr multicycles;  /**< For multi-cycle instructions: Number of cycles for this instruction. */
    logic is_multicycle;  /**< This is a multi-cycle instruction. */
    logic is_branch;      /**< This is a branch instruction. */
    logic is_nop;         /**< Instruction is a no operation and can be optimized. */
    logic synops;         /**< Instruction is a synops instruction. */
  } Predecoded;

  typedef logic[$bits(Predecoded)-1:0] Predecoded_bits;

  //const Predecoded predecoded_zeros = {    
    //1'b0, // logic read_ra;
    //1'b0, // logic read_rb;
    //1'b0, // logic read_rt;
    //1'b0, // logic write_ra;
    //1'b0, // logic write_rt;
    //5'b0, // Reg_index ra;
    //5'b0, // Reg_index rb;
    //5'b0, // Reg_index rt;
    //1'b0, // logic b_immediate;   [>*< Operand b is immediate. <]

    //1'b0, // logic read_ctr;
    //1'b0, // logic write_ctr;
    //1'b0, // logic read_lnk;
    //1'b0, // logic write_lnk;
    //8'b0, // logic[7:0] write_cr;
    //8'b0, // logic[7:0] read_cr_0;
    //8'b0, // logic[7:0] read_cr_1;
    //8'b0, // logic[7:0] read_cr_2;
    //1'b0, // logic read_xer;
    //1'b0, // logic write_xer;
    //XER_DEST_ALL, // Xer_dest xer_dest;
    //1'b0, // logic read_spr;
    //1'b0, // logic read_spr2;
    //Spr_null, // Spr_reduced spr;
    //Spr_null, // Spr_reduced spr2;
    //1'b0, // logic write_spr;
    //Spr_null, // Spr_reduced spr_dest;
    //1'b0, // logic write_mem;
    //1'b0, // logic read_msr;
    //1'b0, // logic write_msr;

    //FUB_BRANCH, // Fu_set fu_set;        [>*< Instruction belongs to this set of functional units. <]
    //1'b0, // logic context_sync;   [>*< Instruction is context synchronizing. <]
    //1'b0, // logic mem_bar;        [>*< Instruction is a memory barrier. <]
    //1'b0, // logic halt;           [>*< Instruction causes a processor halt. <]
    //1'b0, // logic nd_latency;     [>*< Instruction has non-deterministic delay. <]
    //6'b0, // Inst_latency latency; [>*< Number of cycles until write-back of this instruction. <]
    //5'b0, // Seq_ctr multicycles;  [>*< For multi-cycle instructions: Number of cycles for this instruction. <]
    //1'b0, // logic is_multicycle;  [>*< This is a multi-cycle instruction. <]
    //1'b0  // logic is_branch;      [>*< This is a branch instruction. <]
  //};

  function automatic Predecoded predecoded_zeros();
    Predecoded rv;

    rv.read_ra = '0;
    rv.read_rb = '0;
    rv.read_rt = '0;
    rv.write_ra = '0;
    rv.write_rt = '0;
    rv.ra = '0;
    rv.rb = '0;
    rv.rt = '0;
    rv.b_immediate = '0;

    rv.read_ctr = '0;
    rv.write_ctr = '0;
    rv.read_lnk = '0;
    rv.write_lnk = '0;
    rv.write_cr = '0;
    rv.read_cr_0 = '0;
    rv.read_cr_1 = '0;
    rv.read_cr_2 = '0;
    rv.read_xer = '0;
    rv.write_xer = '0;
    rv.xer_dest = XER_ZERO;
    rv.read_spr = '0;
    rv.read_spr2 = '0;
    rv.spr = Pu_types::Spr_null;
    rv.spr2 = Pu_types::Spr_null;
    rv.write_spr = '0;
    rv.spr_dest = Pu_types::Spr_null;
    rv.write_mem = '0;
    rv.read_msr = '0;
    rv.write_msr = '0;

    rv.fu_set        =  FUB_BRANCH;
    rv.context_sync  = '0; 
    rv.mem_bar       = '0; 
    rv.halt          = '0; 
    rv.nd_latency    = '0; 
    rv.latency       = '0; 
    rv.multicycles   = '0; 
    rv.is_multicycle = '0;
    rv.is_branch     = '0;
    rv.is_nop = 1'b0;

    rv.write_nve = 1'b0;

    return rv;
  endfunction

  //---------------------------------------------------------------------------
  // synopsys translate_off
  function automatic string fu_set_to_string(input Fu_set s);
    unique case(s)
      FUB_BRANCH: return "branch";
      FUB_FIXEDPOINT: return "fixedpoint";
      FUB_LOAD_STORE: return "load/store";
      FUB_MUL_DIV: return "mul/div";
      FUB_DIV: return "div";
      FUB_IO: return "io";
      FUB_NEVER: return "never";
      FUB_SYNAPSE: return "synapse";
      FUB_VECTOR: return "vector";
      default: return "undefined";
    endcase
  endfunction
  // synopsys translate_on
  //---------------------------------------------------------------------------
  function automatic Fu_set_id fu_set_id(input Fu_set s);
    Fu_set_id rv;
    for(rv=0; rv<$bits(Fu_set); rv++)
      if(s[rv] == 1'b1)
        break;
    return (rv == $bits(Fu_set)) ? 0 : rv;
  endfunction
  //---------------------------------------------------------------------------
endpackage

// vim: expandtab ts=2 sw=2 softtabstop=2 smarttab: