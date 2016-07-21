# Copyright 2015 Heidelberg University Copyright and related rights are
# licensed under the Solderpad Hardware License, Version 0.51 (the "License");
# you may not use this file except in compliance with the License. You may obtain
# a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
# required by applicable law or agreed to in writing, software, hardware and
# materials distributed under this License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
# the License for the specific language governing permissions and limitations
# under the License.

packages = pu_types_pkg.sv pu_inst_pkg.sv frontend_pkg.sv backend_pkg.sv bus_pkg.sv  load_store_pkg.sv  pu_interrupt_pkg.sv syn_io_pkg.sv valu_pkg.sv vector_pkg.sv

interfaces = alu_ctrl_if.sv branch_ctrl_if.sv branch_data_if.sv branch_hazard_ctrl_if.sv bus_if.sv bypass_if.sv data_hazard_ctrl_if.sv decode_ctrl_if.sv decode_data_if.sv delayed_wb_if.sv fixedpoint_ctrl_if.sv fixedpoint_data_if.sv gpr_file_if.sv inst_fetch_ctrl_if.sv int_sched_if.sv jtag_if.sv jtag_pin_if.sv load_store_ctrl_if.sv load_store_data_if.sv operand_if.sv pu_ctrl_if.sv ram_if.sv register_file_if.sv result_if.sv syn_io_if.sv tag_shiftreg_if.sv timer_if.sv trap_ctrl_if.sv trap_data_if.sv valu_ctrl_if.sv vector_cmp_ctrl_if.sv vector_ls_ctrl_if.sv vector_permute_ctrl_if.sv vector_pls_ctrl_if.sv vector_slice_ctrl_if.sv wb_channel_if.sv write_back_ctrl_if.sv write_back_data_if.sv

m4files = m4out/dec_load_store.preproc.sv m4out/dec_ls_var.preproc.sv  m4out/dec_mul_div.preproc.sv  m4out/fub_div.preproc.sv   m4out/fub_io.preproc.sv   m4out/fub_mul.preproc.sv   m4out/fub_never.preproc.sv  m4out/operand_fetch.preproc.sv   m4out/predecode.preproc.sv m4out/valu_ctrl.preproc.sv

processor = lookup_cache.sv result_shiftreg.sv cr_logic.sv inst_stream.sv byte_rotm.sv rotm.sv spreu.sv cntlz.sv fub_vector.sv vector_ctrl.sv vector_slice.sv vector_ls_shared.sv vector_pls_shared.sv  schedule_single.sv inst_track.sv cycle_counter.sv write_back.sv int_sched.sv gpr_file.sv frontend_single.sv fub_fixedpoint.sv fub_branch.sv fub_load_store.sv load_store.sv fixedpoint.sv parity.sv popcnt.sv logical.sv isel.sv adder.sv exts.sv alu.sv dec_fixedpoint.sv syn_dummy.sv bus_dummy.sv timer_unit.sv l1_memory.sv bit_counter_4.sv pu.sv

omnibus = bus_master_terminator.sv

m4dir = m4out/

all: $(m4files)
	verilator -trace --CFLAGS "-g" -DSYNTHESIS --top-module top -Wno-fatal -Wall --exe dut_top.cpp -y ../../omnibus/src/modules/ -y ../../src/rtl/processor -y ../../src/rtl/include -y ../../src/rtl/packages -y ../../src/rtl/interfaces --cc $(packages) $(interfaces) $(m4files)  $(omnibus) $(processor) top.sv
	cd obj_dir && make -f Vtop.mk

m4out/%.preproc.sv: ../../src/rtl/processor/%.sv
	@awk '/_use_m4_/ {exit 0} {exit 1}' $< && m4 -I../../src/m4/ $< > $@ || cp $< $@
