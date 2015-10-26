#include "Vtop.h"
#include "Vtop_top.h"
#include "Vtop_L1_memory__I0_Ad_IB0_IC2000.h"
#include "Vtop_L1_memory__I0_Ad_IB1000_IC3000.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <fstream>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


int main(int argc, char **argv) {
        Verilated::commandArgs(argc, argv);
        Vtop* top = new Vtop("top");
        Verilated::traceEverOn(true);
        VerilatedVcdC* tfp = new VerilatedVcdC;

        if (argc != 4) {
                fprintf(stderr, "usage: sim <instruction_file> <data_file> <expected_file>\n");
                exit(1);
        }

        int instructions_bin = open(argv[1], O_RDONLY);
        int data_bin = open(argv[2], O_RDONLY);
        int expected_bin = open(argv[3], O_RDONLY);

        if (instructions_bin < 0 || data_bin < 0 || expected_bin < 0) {
                return 1;
        }

        top->trace(tfp, 99);
        tfp->open("top.vcd");
        top->clk = 1;
        top->reset = 1;

        // Reset memory, this is sort of a hack at the moment.
        for (int i = 0; i < 8192; ++i) {
                top->v->imem->bank__BRA__0__KET____DOT__mem[i] = 0;
                top->v->imem->bank__BRA__1__KET____DOT__mem[i] = 0;
                top->v->imem->bank__BRA__2__KET____DOT__mem[i] = 0;
                top->v->imem->bank__BRA__3__KET____DOT__mem[i] = 0;
                top->v->dmem->bank__BRA__0__KET____DOT__mem[i] = 0;
                top->v->dmem->bank__BRA__1__KET____DOT__mem[i] = 0;
                top->v->dmem->bank__BRA__2__KET____DOT__mem[i] = 0;
                top->v->dmem->bank__BRA__3__KET____DOT__mem[i] = 0;
        }

        struct stat ib_st;
        struct stat db_st;
        fstat(instructions_bin, &ib_st);
        fstat(instructions_bin, &db_st);

        // unsigned int* instruction = (unsigned int*)mmap(NULL, ib_st.st_size,  PROT_READ, MAP_FILE | MAP_SHARED, instructions_bin, 0);
        // unsigned int* data = (unsigned int*)mmap(NULL, db_st.st_size,  PROT_READ, MAP_FILE | MAP_SHARED, data_bin, 0);

        unsigned int instruction[] = {0x80600000, 0x80800004, 0x7CA32214, 0x90A00008, 0x7C00007C
};
        unsigned int data[] = {0xf, 0x2, 0x0};

        if (instruction== MAP_FAILED || data == MAP_FAILED)  {
                return 1;
        }

        for (int i = 0; i < sizeof(data)/sizeof(unsigned int); ++i) {
        top->v->dmem->bank__BRA__0__KET____DOT__mem[i] = data[i];
        top->v->dmem->bank__BRA__1__KET____DOT__mem[i] = data[i] >> 8;
        top->v->dmem->bank__BRA__2__KET____DOT__mem[i] = data[i] >> 16;
        top->v->dmem->bank__BRA__3__KET____DOT__mem[i] = data[i] >> 24;
        }
        for (int i = 0; i < sizeof(instruction)/sizeof(unsigned int); ++i) {
        top->v->imem->bank__BRA__0__KET____DOT__mem[i] = instruction[i];
        top->v->imem->bank__BRA__1__KET____DOT__mem[i] = instruction[i] >> 8;
        top->v->imem->bank__BRA__2__KET____DOT__mem[i] = instruction[i] >> 16;
        top->v->imem->bank__BRA__3__KET____DOT__mem[i] = instruction[i] >> 24;
        }


        for (int i=0; i<1000; i++) {
                top->reset = (i < 20);
                // dump variables into VCD file and toggle clock
                for (int clk=0; clk<2; clk++) {
                        tfp->dump (2*i+clk);
                        top->clk = !top->clk;
                        top->eval ();
                }
                if (Verilated::gotFinish())  exit(0);
        }

        tfp->close();
        exit(0);
}
