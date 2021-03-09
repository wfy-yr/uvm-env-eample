// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-03-06 10:21
// Filename     : nr_l2dl_ddr_mem_backdoor.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_DDR_MEM_BACKDOOR__SV
`define NR_L2DL_DDR_MEM_BACKDOOR__SV
class nr_l2dl_ddr_mem_backdoor extends uvm_reg_backdoor;
    nr_l2dl_env_cfg env_cfg;
    `uvm_object_utils(nr_l2dl_ddr_mem_backdoor)
    extern function new(string name= "nr_l2dl_ddr_mem_backdoor");
    extern virtual task write(uvm_reg_item rw);
    extern virtual task read(uvm_reg_item rw);
endclass : nr_l2dl_ddr_mem_backdoor


function nr_l2dl_ddr_mem_backdoor::new(string name = "nr_l2dl_ddr_mem_backdoor"); //{{{
      super.new(name);
endfunction: new //}}}

task nr_l2dl_ddr_mem_backdoor::write(uvm_reg_item rw); //{{{
    uvm_status_e   status; 
    uvm_reg_addr_t base_addr;
    uvm_reg_data_t data;
    uvm_mem   mem;
    bit [7:0] burst_array[];
    int unsigned idx = 0;
    int unsigned n_bytes;
    $cast(mem, rw.element);
    n_bytes = mem.get_n_bytes(); // virtual mem entry is n_bytes, while cdns mem unit is byte

    base_addr = rw.offset * n_bytes; // absolute address of first entry
    //add your code here to do address convertion
    //
    burst_array = new[rw.value.size() * n_bytes];
    foreach(rw.value[ii]) begin
        uvm_reg_data_t data = rw.value[ii];
        repeat(n_bytes) begin
            burst_array[idx] = data[7:0];
            data >>= 8;
            idx ++;
        end
    end
    foreach(burst_array[ii]) begin
        env_cfg.memory[ii+base_addr]= burst_array[ii];
    end
    rw.status = UVM_IS_OK;
endtask: write //}}}

task nr_l2dl_ddr_mem_backdoor::read(uvm_reg_item rw); //{{{
    uvm_status_e   status; 
    uvm_reg_addr_t base_addr;
    uvm_reg_data_t data;
    uvm_mem   mem;
    bit [7:0] burst_array[];
    int unsigned idx = 0;
    int unsigned n_bytes;
    $cast(mem, rw.element);
    n_bytes = mem.get_n_bytes(); // virtual mem entry is n_bytes, while cdns mem unit is byte

    base_addr = rw.offset * n_bytes; // absolute address of first entry
    //add your code here to do address convertion
    //
    burst_array = new[rw.value.size() * n_bytes];

    foreach(burst_array[ii]) begin
        burst_array[ii] = env_cfg.memory[ii+base_addr];
    end

    foreach(rw.value[ii]) begin
        uvm_reg_data_t data;
        for(int jj=0; jj < n_bytes; jj++) begin
            data[8*jj+:8] = burst_array[idx];
        end
        idx ++;
        rw.value[ii] = data;
        rw.status = UVM_IS_OK;
    end
endtask: read //}}}
`endif
