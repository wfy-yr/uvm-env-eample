// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 18:49
// Filename     : nr_l2dl_dtc_rdma_monitor.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_DTC_RDMA_MONITOR__SV
`define NR_L2DL_DTC_RDMA_MONITOR__SV

class nr_l2dl_dtc_rdma_monitor extends uvm_monitor;
    virtual nr_l2dl_top_intf top_vif;
    virtual nr_l2dl_dtc_rdma_intf vif;
    int num_col = 0;

    nr_l2dl_dtc_rdma_agent_cfg   cfg;
    nr_l2dl_dtc_rdma_coverage    cg;

    //int bit_num;
    string cov_name;

    uvm_analysis_port #(nr_l2dl_fifo_trans)    mon_port;
    uvm_analysis_port #(nr_l2dl_fifo_trans)    mon_port_base;

    uvm_tlm_analysis_fifo #(rx_mac_l1_tb_info) l1_tb_info_buffer;
    uvm_tlm_analysis_fifo #(rx_mac_l2_tb_info) l2_tb_info_buffer;

    `uvm_component_utils_begin(nr_l2dl_dtc_rdma_monitor)
        `uvm_field_int(num_col, UVM_ALL_ON)
    `uvm_component_utils_end


    extern function new (string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual protected task collect_transfer(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    extern virtual task collect_mce_pld_trans(input bit [127:0] dma_mem[3][bit [31:0]], input rx_mac_mce_trans mce_node_tr);
    extern virtual task collect_dl_node0_pld_trans(input int dl_node0_idx, input bit [127:0] dma_mem[3][bit [31:0]], input rx_mac_dl_node0 dl_node0_tr);
endclass: nr_l2dl_dtc_rdma_monitor

function nr_l2dl_dtc_rdma_monitor::new (string name, uvm_component parent);
    super.new(name, parent);
    mon_port = new("mon_port", this);
    mon_port_base = new("mon_port_base", this);
    l1_tb_info_buffer = new("l1_tb_info_buffer", this); 
    l2_tb_info_buffer = new("l2_tb_info_buffer", this);
endfunction : new

function void nr_l2dl_dtc_rdma_monitor::build_phase(uvm_phase phase); //{{{
    super.build_phase(phase);
    if(!uvm_config_db#(virtual nr_l2dl_dtc_rdma_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get vif !"))
    end

    if(!uvm_config_db#(virtual nr_l2dl_top_intf)::get(this, "", "vif", top_vif)) begin
        `uvm_fatal("NOCFG", $sformatf("[%s] Cannot get nr_l2dl_top_vif", get_full_name()))
    end

    if(!uvm_config_db#(nr_l2dl_dtc_rdma_agent_cfg)::get(this, "", "cfg", cfg)) begin
       `uvm_fatal(get_full_name(), $psprintf("Can not get cfg !"))
    end

    if(cfg.coverage_enable) begin
        cg = new($sformatf({get_full_name(), "_cg"}));   
    end
endfunction : build_phase //}}}


task nr_l2dl_dtc_rdma_monitor::run_phase(uvm_phase phase); //{{{
    //bit bit_stream[];
    //nr_l2dl_dtc_rdma_trans    mon_tr;

    //mon_tr = nr_l2dl_dtc_rdma_trans::type_id::create("mon_tr", this);
    //void'(mon_tr.pack(bit_stream, default_packer));
    //bit_num = bit_stream.size();

    //forever begin
        collect_transfer(phase);
    //end
endtask : run_phase //}}}

task nr_l2dl_dtc_rdma_monitor::collect_transfer(uvm_phase phase); //{{{
    bit bit64_stream[];
    bit bit128_stream[];
    bit bit256_stream[];
    rx_mac_l1_tb_info      tb_info1,l1_tb_info;
    rx_mac_l2_tb_info      tb_info2,l2_tb_info;
    rx_mac_mce_trans       mce_node;
    rx_mac_dl_node0        dl_node0,dl_node0_acc;
    rx_mac_acc_node        acc_node;
    nr_l2dl_dtc_pld_trans  mce_pld;
    bit [127:0] dma_mem[3][bit [31:0]];
    int blk_ref_cnt[bit [31:0]];
    bit [31:0] blk_addr_store; 
    int blk_addr_chk;    
    bit [31:0] rsvd_flag_addr;
    bit [31:0] des2rsvd_addr;
    int dl_node0_num;
    bit [63:0] cp_hdr;

    fork
        forever begin
            @(posedge top_vif.blkaddr_fifo_w);
            blk_ref_cnt[top_vif.blkaddr_fifo_din[31:0]]=0;
        end
        forever begin
            @(vif.moncb iff vif.moncb.mem_rd == 1);
            //if(vif.moncb.mem_addr=='h8f5) `uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: mem_data=%0h", vif.moncb.mem_data), UVM_DEBUG)
            if(dma_mem[1].exists(vif.moncb.mem_addr))begin
                dma_mem[2][vif.moncb.mem_addr] = vif.moncb.mem_data & {{8{~vif.moncb.mem_len[15]}},{8{~vif.moncb.mem_len[14]}},{8{~vif.moncb.mem_len[13]}},{8{~vif.moncb.mem_len[12]}},{8{~vif.moncb.mem_len[11]}},{8{~vif.moncb.mem_len[10]}},{8{~vif.moncb.mem_len[9]}},{8{~vif.moncb.mem_len[8]}},{8{~vif.moncb.mem_len[7]}},{8{~vif.moncb.mem_len[6]}},{8{~vif.moncb.mem_len[5]}},{8{~vif.moncb.mem_len[4]}},{8{~vif.moncb.mem_len[3]}},{8{~vif.moncb.mem_len[2]}},{8{~vif.moncb.mem_len[1]}},{8{~vif.moncb.mem_len[0]}}}; 
                //if(vif.moncb.mem_addr=='h8f5) `uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: dma_mem[2][%0h]=%0h", vif.moncb.mem_addr,dma_mem[2][vif.moncb.mem_addr]), UVM_DEBUG)
            end else if(dma_mem[0].exists(vif.moncb.mem_addr)) begin
                dma_mem[1][vif.moncb.mem_addr] = vif.moncb.mem_data & {{8{~vif.moncb.mem_len[15]}},{8{~vif.moncb.mem_len[14]}},{8{~vif.moncb.mem_len[13]}},{8{~vif.moncb.mem_len[12]}},{8{~vif.moncb.mem_len[11]}},{8{~vif.moncb.mem_len[10]}},{8{~vif.moncb.mem_len[9]}},{8{~vif.moncb.mem_len[8]}},{8{~vif.moncb.mem_len[7]}},{8{~vif.moncb.mem_len[6]}},{8{~vif.moncb.mem_len[5]}},{8{~vif.moncb.mem_len[4]}},{8{~vif.moncb.mem_len[3]}},{8{~vif.moncb.mem_len[2]}},{8{~vif.moncb.mem_len[1]}},{8{~vif.moncb.mem_len[0]}}}; 
                //if(vif.moncb.mem_addr=='h8f5) `uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: dma_mem[1][%0h]=%0h", vif.moncb.mem_addr,dma_mem[1][vif.moncb.mem_addr]), UVM_DEBUG)
            end else begin
                dma_mem[0][vif.moncb.mem_addr] = vif.moncb.mem_data & {{8{~vif.moncb.mem_len[15]}},{8{~vif.moncb.mem_len[14]}},{8{~vif.moncb.mem_len[13]}},{8{~vif.moncb.mem_len[12]}},{8{~vif.moncb.mem_len[11]}},{8{~vif.moncb.mem_len[10]}},{8{~vif.moncb.mem_len[9]}},{8{~vif.moncb.mem_len[8]}},{8{~vif.moncb.mem_len[7]}},{8{~vif.moncb.mem_len[6]}},{8{~vif.moncb.mem_len[5]}},{8{~vif.moncb.mem_len[4]}},{8{~vif.moncb.mem_len[3]}},{8{~vif.moncb.mem_len[2]}},{8{~vif.moncb.mem_len[1]}},{8{~vif.moncb.mem_len[0]}}}; 
                //if(vif.moncb.mem_addr=='h8f5) `uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: dma_mem[0][%0h]=%0h", vif.moncb.mem_addr,dma_mem[0][vif.moncb.mem_addr]), UVM_DEBUG)
            end
        end
        for(int ii=0; ii<`TB_NUM+`TB_ADD; ii++)begin 
            if(ii<=cfg.tb_info1_space-1)begin
                @(vif.moncb iff ((vif.moncb.mem_addr == cfg.tb_info1_dma_addr+ii*16) && (vif.moncb.mem_rd == 1)));
            end else begin
                @(vif.moncb iff ((vif.moncb.mem_addr == cfg.tb_info1_dma_addr+(ii-cfg.tb_info1_space)*16) && (vif.moncb.mem_rd == 1)));
            end
            bit128_stream = new[128];
            foreach(bit128_stream[jj])begin
                bit128_stream[jj] = vif.moncb.mem_data[jj];
            end
            tb_info1 = rx_mac_l1_tb_info::type_id::create("tb_info1", this);
            void'(tb_info1.unpack(bit128_stream, default_packer));
            l1_tb_info_buffer.put(tb_info1); 
            tb_info1.stream_id = cfg.stream_id0;
            mon_port.write(tb_info1);
        end
        for(int ii=0; ii<`TB_NUM+`TB_ADD; ii++)begin 
            if(ii<=cfg.tb_info2_space-1)begin
                @(vif.moncb iff ((vif.moncb.mem_addr == cfg.tb_info2_dma_addr+ii*32) && (vif.moncb.mem_rd == 1)));
            end else begin
                @(vif.moncb iff ((vif.moncb.mem_addr == cfg.tb_info2_dma_addr+(ii-cfg.tb_info2_space)*32) && (vif.moncb.mem_rd == 1)));
            end
            bit256_stream = new[256];
            for(int jj=0; jj<128; jj++)begin
                bit256_stream[jj] = vif.moncb.mem_data[jj];
            end
            if(ii<=cfg.tb_info2_space-1)begin
                @(vif.moncb iff ((vif.moncb.mem_addr == cfg.tb_info2_dma_addr+16+ii*32) && (vif.moncb.mem_rd == 1)));
            end else begin
                @(vif.moncb iff ((vif.moncb.mem_addr == cfg.tb_info2_dma_addr+16+(ii-cfg.tb_info2_space)*32) && (vif.moncb.mem_rd == 1)));
            end
            for(int jj=0; jj<128; jj++)begin
                bit256_stream[jj+128] = vif.moncb.mem_data[jj];
            end
            tb_info2 = rx_mac_l2_tb_info::type_id::create("tb_info2", this);
            void'(tb_info2.unpack(bit256_stream, default_packer));
            l2_tb_info_buffer.put(tb_info2); 
            tb_info2.stream_id = cfg.stream_id1;
            mon_port.write(tb_info2);
        end
        forever begin
            @(posedge top_vif.dtc_tb_int);
            l1_tb_info_buffer.get(l1_tb_info);
            //l1_mce
            for(int ii=0; ii<$ceil(l1_tb_info.mce_node_num/2); ii++)begin
                if(dma_mem[2].exists(cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)))begin
                    bit64_stream=new[64];
                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[2][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][jj];
                    end
                    mce_node = rx_mac_mce_trans::type_id::create("mce_node", this);
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    mce_node.stream_id = cfg.stream_id2;
                    if(dma_mem[2][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][63:0] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end

                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[2][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][jj+64];
                    end
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    if(dma_mem[2][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][127:64] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end
                end else if(dma_mem[1].exists(cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii))) begin
                    bit64_stream=new[64];
                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[1][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][jj];
                    end
                    mce_node = rx_mac_mce_trans::type_id::create("mce_node", this);
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    mce_node.stream_id = cfg.stream_id2;
                    if(dma_mem[1][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][63:0] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end

                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[1][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][jj+64];
                    end
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    if(dma_mem[1][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][127:64] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end
                end else begin
                    bit64_stream=new[64];
                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[0][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][jj];
                    end
                    mce_node = rx_mac_mce_trans::type_id::create("mce_node", this);
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    mce_node.stream_id = cfg.stream_id2;
                    if(dma_mem[0][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][63:0] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end

                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[0][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][jj+64];
                    end
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    if(dma_mem[0][cfg.macce_node1_dma_addr+8*(l1_tb_info.first_mce_node_idx+2*ii)][127:64] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end
                end
            end
        end
        forever begin
            @(posedge top_vif.dtc_tb_int);
            l2_tb_info_buffer.get(l2_tb_info);
            //l2_mce
            for(int ii=0; ii<$ceil(l2_tb_info.mce_node_num/2); ii++)begin
                if(dma_mem[2].exists(cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)))begin
                    bit64_stream=new[64];
                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[2][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][jj];
                    end
                    mce_node = rx_mac_mce_trans::type_id::create("mce_node", this);
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    mce_node.stream_id = cfg.stream_id3;
                    if(dma_mem[2][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][63:0] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end

                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[2][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][jj+64];
                    end
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    if(dma_mem[2][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][127:64] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end
                end else if(dma_mem[1].exists(cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii))) begin
                    bit64_stream=new[64];
                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[1][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][jj];
                    end
                    mce_node = rx_mac_mce_trans::type_id::create("mce_node", this);
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    mce_node.stream_id = cfg.stream_id3;
                    if(dma_mem[1][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][63:0] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end

                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[1][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][jj+64];
                    end
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    if(dma_mem[1][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][127:64] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end
                end else begin
                    bit64_stream=new[64];
                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[0][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][jj];
                    end
                    mce_node = rx_mac_mce_trans::type_id::create("mce_node", this);
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    mce_node.stream_id = cfg.stream_id3;
                    if(dma_mem[0][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][63:0] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end

                    foreach(bit64_stream[jj])begin
                        bit64_stream[jj] = dma_mem[0][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][jj+64];
                    end
                    void'(mce_node.unpack(bit64_stream, default_packer));
                    if(dma_mem[0][cfg.macce_node2_dma_addr+8*(l2_tb_info.first_mce_node_idx+2*ii)][127:64] !='h0)begin
                        mon_port.write(mce_node);
                        collect_mce_pld_trans(dma_mem,mce_node);
                    end
                end
            end
            //acc_node
            for(int ii=0; ii<l2_tb_info.nr_l2_acc_num+top_vif.padding_flag; ii++)begin
                bit128_stream=new[128];
                foreach(bit128_stream[jj])begin
                    if(l2_tb_info.first_l2_acc_idx+ii<cfg.acc_node_space)begin
                        if(dma_mem[2].exists(cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii)))begin
                            bit128_stream[jj] = dma_mem[2][cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii)][jj];
                        end else if(dma_mem[1].exists(cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii))) begin
                            bit128_stream[jj] = dma_mem[1][cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii)][jj];
                        end else begin
                            bit128_stream[jj] = dma_mem[0][cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii)][jj];
                        end
                    end else begin
                        if(dma_mem[2].exists(cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii-cfg.acc_node_space)))begin
                            bit128_stream[jj] = dma_mem[2][cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii-cfg.acc_node_space)][jj];
                        end else if(dma_mem[1].exists(cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii-cfg.acc_node_space))) begin
                            bit128_stream[jj] = dma_mem[1][cfg.acc_node_dma_addr+16*(l2_tb_info.first_l2_acc_idx+ii-cfg.acc_node_space)][jj];
                        end
                    end
                end
                acc_node = rx_mac_acc_node::type_id::create("acc_node", this);
                void'(acc_node.unpack(bit128_stream, default_packer));
                acc_node.stream_id = cfg.stream_id7;
                mon_port.write(acc_node);
                //dl_node0 from acc_node
                for(int ii=0; ii<acc_node.l2_node_num; ii++)begin
                    bit256_stream=new[256];
                    for(int jj=0; jj<128; jj++)begin
                        if(dma_mem[2].exists(cfg.dl_node0_dma_addr+32*(acc_node.first_l2dl_node_idx+ii)))begin
                            bit256_stream[jj] = dma_mem[2][cfg.dl_node0_dma_addr+32*(acc_node.first_l2dl_node_idx+ii)][jj];
                        end else if(dma_mem[1].exists(cfg.dl_node0_dma_addr+32*(acc_node.first_l2dl_node_idx+ii))) begin
                            bit256_stream[jj] = dma_mem[1][cfg.dl_node0_dma_addr+32*(acc_node.first_l2dl_node_idx+ii)][jj];
                        end else begin
                            bit256_stream[jj] = dma_mem[0][cfg.dl_node0_dma_addr+32*(acc_node.first_l2dl_node_idx+ii)][jj];
                        end
                    end
                    for(int jj=0; jj<128; jj++)begin
                        if(dma_mem[2].exists(cfg.dl_node0_dma_addr+16*(2*acc_node.first_l2dl_node_idx+2*ii+1)))begin
                            bit256_stream[jj+128] = dma_mem[2][cfg.dl_node0_dma_addr+16*(2*acc_node.first_l2dl_node_idx+2*ii+1)][jj];
                        end else if(dma_mem[1].exists(cfg.dl_node0_dma_addr+16*(2*acc_node.first_l2dl_node_idx+2*ii+1))) begin
                            bit256_stream[jj+128] = dma_mem[1][cfg.dl_node0_dma_addr+16*(2*acc_node.first_l2dl_node_idx+2*ii+1)][jj];
                        end else begin
                            bit256_stream[jj+128] = dma_mem[0][cfg.dl_node0_dma_addr+16*(2*acc_node.first_l2dl_node_idx+2*ii+1)][jj];
                        end
                    end
                    dl_node0_acc = rx_mac_dl_node0::type_id::create("dl_node0_acc", this);
                    void'(dl_node0_acc.unpack(bit256_stream, default_packer));
                    dl_node0_acc.stream_id = cfg.stream_id8;
                    mon_port.write(dl_node0_acc);
                end
            end
            //dl_node0
            for(int ii=0; ii<l2_tb_info.l2dl_node_num; ii++)begin
                bit256_stream=new[256];
                for(int jj=0; jj<128; jj++)begin
                    if(dma_mem[2].exists(cfg.dl_node0_dma_addr+32*(l2_tb_info.first_l2dl_node_out_idx+ii)))begin
                        bit256_stream[jj] = dma_mem[2][cfg.dl_node0_dma_addr+32*(l2_tb_info.first_l2dl_node_out_idx+ii)][jj];
                    end else if(dma_mem[1].exists(cfg.dl_node0_dma_addr+32*(l2_tb_info.first_l2dl_node_out_idx+ii))) begin
                        bit256_stream[jj] = dma_mem[1][cfg.dl_node0_dma_addr+32*(l2_tb_info.first_l2dl_node_out_idx+ii)][jj];
                    end else begin
                        bit256_stream[jj] = dma_mem[0][cfg.dl_node0_dma_addr+32*(l2_tb_info.first_l2dl_node_out_idx+ii)][jj];
                    end
                end
                for(int jj=0; jj<128; jj++)begin
                    if(dma_mem[2].exists(cfg.dl_node0_dma_addr+16*(2*l2_tb_info.first_l2dl_node_out_idx+2*ii+1)))begin
                        bit256_stream[jj+128] = dma_mem[2][cfg.dl_node0_dma_addr+16*(2*l2_tb_info.first_l2dl_node_out_idx+2*ii+1)][jj];
                    end else if(dma_mem[1].exists(cfg.dl_node0_dma_addr+16*(2*l2_tb_info.first_l2dl_node_out_idx+2*ii+1))) begin
                        bit256_stream[jj+128] = dma_mem[1][cfg.dl_node0_dma_addr+16*(2*l2_tb_info.first_l2dl_node_out_idx+2*ii+1)][jj];
                    end else begin
                        bit256_stream[jj+128] = dma_mem[0][cfg.dl_node0_dma_addr+16*(2*l2_tb_info.first_l2dl_node_out_idx+2*ii+1)][jj];
                    end
                end
                dl_node0 = rx_mac_dl_node0::type_id::create("dl_node0", this);
                void'(dl_node0.unpack(bit256_stream, default_packer));
                dl_node0.stream_id = cfg.stream_id5;
                mon_port.write(dl_node0);
                dl_node0_num++;
                //cp_header chk
                if((cfg.lc_cfg[dl_node0.lcid].cp_header_en == 1) && (dl_node0.dec_pdcp_hdr == 1))begin
                    cp_hdr={10'h0,dl_node0.qfi,cfg.lc_cfg[dl_node0.lcid].rb_id,8'h0,dl_node0.data_byte_len-8};
                    assert(dma_mem[0][dl_node0.des_addr][63:0] == cp_hdr)
                    else `uvm_error($sformatf("%25s", get_full_name()), $sformatf("[CP_HDR_CHK][%0d]Compare ERROR: Insert=%0h, Expect=%0h",dl_node0_num, dma_mem[0][dl_node0.des_addr][63:0], cp_hdr))
                end
                //resvd_intv_size chk
                if(((blk_ref_cnt.exists(dl_node0.des_addr-cfg.lc_cfg[dl_node0.lcid].resvd_intv_size-'h40+8*cfg.lc_cfg[dl_node0.lcid].cp_header_en))&&(dl_node0.dec_pdcp_hdr==1)) || ((blk_ref_cnt.exists(dl_node0.des_addr-'h40))&&(dl_node0.dec_pdcp_hdr==0)))begin
                    des2rsvd_addr = dl_node0.dec_pdcp_hdr==1 ? dl_node0.des_addr-cfg.lc_cfg[dl_node0.lcid].resvd_intv_size+8*cfg.lc_cfg[dl_node0.lcid].cp_header_en : dl_node0.des_addr;
                    assert(des2rsvd_addr[5:0] == 'h0)
                    else `uvm_error($sformatf("%25s", get_full_name()), $sformatf("[RSVD_ADDR_CHK][%0d]Compare ERROR: Address misalignment",dl_node0_num))
                    rsvd_flag_addr = dl_node0.des_addr+dl_node0.data_byte_len;
                end else begin
                    if(dl_node0.dec_pdcp_hdr==1)begin
                        des2rsvd_addr=dl_node0.des_addr-cfg.lc_cfg[dl_node0.lcid].resvd_intv_size+8*cfg.lc_cfg[dl_node0.lcid].cp_header_en;
                        assert((des2rsvd_addr>=rsvd_flag_addr)&&(des2rsvd_addr[5:0]=='h0))
                        else `uvm_error($sformatf("%25s", get_full_name()), $sformatf("[RSVD_ADDR_CHK][%0d]Compare ERROR: des2rsvd_addr=%0h < rsvd_flag_addr=%0h or Address misalignment", dl_node0_num, des2rsvd_addr, rsvd_flag_addr))
                        rsvd_flag_addr= dl_node0.des_addr+dl_node0.data_byte_len;
                    end else begin
                        assert(dl_node0.des_addr[5:0] == 'h0)
                        else `uvm_error($sformatf("%25s", get_full_name()), $sformatf("[RSVD_ADDR_CHK][%0d]Compare ERROR: Address misalignment",dl_node0_num))
                        rsvd_flag_addr= dl_node0.des_addr+dl_node0.data_byte_len;
                    end
                end
                //blk ref cnt chk
                foreach(blk_ref_cnt[jj])begin
                    if((dl_node0.des_addr<jj+1024*(2**(top_vif.blk_size+3))) && (dl_node0.des_addr>jj))begin
                        blk_ref_cnt[jj] = blk_ref_cnt[jj] + 1; 
                        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: max_addr=%0h, blk_ref_cnt[%0h]=%0d", jj+1024*(2**(top_vif.blk_size+3)), jj, blk_ref_cnt[jj]), UVM_DEBUG)
                    end
                end
                if(blk_addr_store=='h0)begin
                   blk_addr_store= dl_node0.dec_pdcp_hdr==1 ? dl_node0.des_addr-cfg.lc_cfg[dl_node0.lcid].resvd_intv_size-'h40+8*cfg.lc_cfg[dl_node0.lcid].cp_header_en : dl_node0.des_addr-'h40; 
                end else if((blk_addr_store+1024*(2**(top_vif.blk_size+3))<dl_node0.des_addr) || (dl_node0.des_addr<blk_addr_store))begin
                   blk_addr_chk++;
                   if((dma_mem[0][blk_addr_store+'h8][111:96] != blk_ref_cnt[blk_addr_store]) || (blk_ref_cnt[blk_addr_store] == 0))begin
                        `uvm_error($sformatf("%25s", get_full_name()), $sformatf("[BLK_ADDR_CNT][%0d]Compare ERROR: Insert(%0h)=%0d, Expect(%0h)=%0d", blk_addr_chk, blk_addr_store+'h8, dma_mem[0][blk_addr_store+'h8][111:96], blk_addr_store, blk_ref_cnt[blk_addr_store]))
                   end else begin
                        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("[BLK_ADDR_CNT][%0d]Compare OK: Insert(%0h)=%0d, Expect(%0h)=%0d", blk_addr_chk, blk_addr_store+'h8, dma_mem[0][blk_addr_store+'h8][111:96], blk_addr_store, blk_ref_cnt[blk_addr_store]), UVM_DEBUG)
                   end
                   blk_addr_store = dl_node0.dec_pdcp_hdr==1 ? dl_node0.des_addr-cfg.lc_cfg[dl_node0.lcid].resvd_intv_size-'h40+8*cfg.lc_cfg[dl_node0.lcid].cp_header_en : dl_node0.des_addr-'h40; 
                end
                //dl_node0 pld chk
                collect_dl_node0_pld_trans(ii,dma_mem,dl_node0);
            end
        end
    join
    //mon_tr.data = vif.moncb.data;
    //mon_tr.addr = vif.moncb.addr;

    //send mon_tr to scb_transformer or scoreboard
    //void'(mon_tr.unpack(bit_stream, default_packer));
    //mon_tr.stream_id = cfg.stream_id;
    //mon_tr.ch_id = cfg.ch_id;
    //mon_port.write(mon_tr);
    //mon_port_base.write(mon_tr);
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: read dma monitor collected %0d transfers", num_col), UVM_DEBUG)

    //if(cfg.coverage_enable) begin
    //    cg.sample_tr(mon_tr);
    //    cg.sample_cfg(cfg);
    //end
    num_col++;
    cfg.mon_busy = 0;

endtask : collect_transfer //}}}

task nr_l2dl_dtc_rdma_monitor::collect_mce_pld_trans(input bit [127:0] dma_mem[3][bit [31:0]], input rx_mac_mce_trans mce_node_tr); //{{{
    real mce_node_l; 
    bit [3:0] mce_start_offset; 
    nr_l2dl_dtc_pld_trans mce_pld;

    mce_node_l = mce_node_tr.l; 
    mce_start_offset = mce_node_tr.mce_start_addr[3:0]; 
    case(mce_node_tr.lcid) 
         47    : mce_node_l = 2;
         48    : mce_node_l = 2;
         49    : mce_node_l = 3;
         51    : mce_node_l = 2;
         52    : mce_node_l = 2;
         56    : mce_node_l = 1;
         57    : mce_node_l = 4;
         58    : mce_node_l = 1;
         61    : mce_node_l = 1;
         62    : mce_node_l = 6;
    endcase    
    //`uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: mce_node_l=%0h $ceil(mce_node_l/16)=%0h mce_node_tr is \n%s", mce_node_l,$ceil(mce_node_l/16),mce_node_tr.sprint()), UVM_DEBUG)
    for(int ii=0; ii<$ceil(mce_node_l/16); ii++)begin
        mce_pld = nr_l2dl_dtc_pld_trans::type_id::create("mce_pld", this);
        if(ii==0)begin
            for(int jj=0; jj<128-8*mce_start_offset; jj++)begin
                if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*ii))begin
                    mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*ii))begin
                    mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                end else begin
                    mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                end
            end
            mce_node_tr.mce_start_addr[3:0] = 'h0;
            for(int jj=128-8*mce_start_offset; jj<128; jj++)begin
                if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                    mce_pld.data[jj] = (($ceil(mce_node_l/16)>1) || (mce_start_offset+mce_node_l>16)) ? dma_mem[2][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128] : 'h0;
                end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                    mce_pld.data[jj] = (($ceil(mce_node_l/16)>1) || (mce_start_offset+mce_node_l>16)) ? dma_mem[1][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128] : 'h0;
                end else begin
                    mce_pld.data[jj] = (($ceil(mce_node_l/16)>1) || (mce_start_offset+mce_node_l>16)) ? dma_mem[0][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128] : 'h0;
                end
            end
        end else if(ii==$ceil(mce_node_l/16)-1)begin
            if(mce_node_tr.l%16 == 0) begin
                for(int jj=0; jj<128-8*mce_start_offset; jj++)begin
                    if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*ii))begin
                        mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*ii))begin
                        mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end else begin
                        mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end
                end
                for(int jj=128-8*mce_start_offset; jj<128; jj++)begin
                    if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                        mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                    end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                        mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                    end else begin
                        mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                    end
                end
            end else if(mce_start_offset+mce_node_tr.l%16>=16)begin
                for(int jj=0; jj<128-8*mce_start_offset; jj++)begin
                    if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*ii))begin
                        mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*ii))begin
                        mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end else begin
                        mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end
                end
                for(int jj=128-8*mce_start_offset; jj<8*(mce_node_tr.l%16); jj++)begin
                    if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                        mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                    end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                        mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                    end else begin
                        mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                    end
                end
                for(int jj=8*(mce_node_tr.l%16); jj<128; jj++)begin
                    mce_pld.data[jj] = 'h0;
                end
            end else begin
                for(int jj=0; jj<8*(mce_node_tr.l%16); jj++)begin
                    if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*ii))begin
                        mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*ii))begin
                        mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end else begin
                        mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                    end
                end
                for(int jj=8*(mce_node_tr.l%16); jj<128; jj++)begin
                    mce_pld.data[jj] = 'h0;
                end
            end
        end else begin
            for(int jj=0; jj<128-8*mce_start_offset; jj++)begin
                if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*ii))begin
                    mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*ii))begin
                    mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                end else begin
                    mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*ii][jj+8*mce_start_offset];
                end
            end
            for(int jj=128-8*mce_start_offset; jj<128; jj++)begin
                if(dma_mem[2].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                    mce_pld.data[jj] = dma_mem[2][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                end else if(dma_mem[1].exists(mce_node_tr.mce_start_addr+16*(ii+1)))begin
                    mce_pld.data[jj] = dma_mem[1][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                end else begin
                    mce_pld.data[jj] = dma_mem[0][mce_node_tr.mce_start_addr+16*(ii+1)][jj+8*mce_start_offset-128];
                end
            end
        end
        mce_pld.stream_id = cfg.stream_id4;
        mce_pld.addr = (ii == 0) ? mce_node_tr.mce_start_addr+mce_start_offset : mce_node_tr.mce_start_addr+16*ii;
        mon_port.write(mce_pld);
        //`uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: mce_pld is \n%s", mce_pld.sprint()), UVM_DEBUG)
    end
endtask : collect_mce_pld_trans //}}} 

task nr_l2dl_dtc_rdma_monitor::collect_dl_node0_pld_trans(input int dl_node0_idx, input bit [127:0] dma_mem[3][bit [31:0]], input rx_mac_dl_node0 dl_node0_tr); //{{{
    real dl_node0_l; 
    bit [3:0] dl_node0_start_offset; 
    nr_l2dl_dtc_pld_trans dl_node0_pld;
 
    dl_node0_l = dl_node0_tr.data_byte_len; 

    dl_node0_start_offset = dl_node0_tr.des_addr[3:0]; 
    //`uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: dl_node0_l=%0h $ceil(dl_node0_l/16)=%0h dl_node0_tr is \n%s", dl_node0_l,$ceil(dl_node0_l/16),dl_node0_tr.sprint()), UVM_DEBUG)
    for(int ii=0; ii<$ceil(dl_node0_l/16); ii++)begin
        dl_node0_pld = nr_l2dl_dtc_pld_trans::type_id::create("dl_node0_pld", this);
        if(ii==0)begin
            for(int jj=0; jj<128-8*dl_node0_start_offset; jj++)begin
                if(dma_mem[2].exists(dl_node0_tr.des_addr+16*ii))begin
                    dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*ii))begin
                    dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                end else begin
                    dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                end
            end
            dl_node0_tr.des_addr[3:0] = 'h0;
            for(int jj=128-8*dl_node0_start_offset; jj<128; jj++)begin
                if(dma_mem[2].exists(dl_node0_tr.des_addr+16*(ii+1)))begin
                    dl_node0_pld.data[jj] = (($ceil(dl_node0_l/16)>1) || (dl_node0_start_offset+dl_node0_l>16)) ? dma_mem[2][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128] : 'h0;
                end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*(ii+1)))begin
                    dl_node0_pld.data[jj] = (($ceil(dl_node0_l/16)>1) || (dl_node0_start_offset+dl_node0_l>16)) ? dma_mem[1][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128] : 'h0;
                end else begin
                    dl_node0_pld.data[jj] = (($ceil(dl_node0_l/16)>1) || (dl_node0_start_offset+dl_node0_l>16)) ? dma_mem[0][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128] : 'h0;
                end
            end
        end else if(ii==$ceil(dl_node0_l/16)-1)begin
            if(dl_node0_tr.data_byte_len%16 == 0) begin
                for(int jj=0; jj<128-8*dl_node0_start_offset; jj++)begin
                    if(dma_mem[2].exists(dl_node0_tr.des_addr+16*ii))begin
                        dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[2][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*ii))begin
                        dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[1][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end else begin
                        dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[0][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end
                end
                for(int jj=128-8*dl_node0_start_offset; jj<128; jj++)begin
                    if(dma_mem[2].exists(dl_node0_tr.des_addr+16*(ii+1)))begin
                        dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                    end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*(ii+1)))begin
                        dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                    end else begin
                        dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                    end
                end
            end else if(dl_node0_start_offset+dl_node0_tr.data_byte_len%16>=16)begin
                for(int jj=0; jj<128-8*dl_node0_start_offset; jj++)begin
                    if(dma_mem[2].exists(dl_node0_tr.des_addr+16*ii))begin
                        dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[2][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*ii))begin
                        dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[1][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end else begin
                        dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[0][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end
                end
                for(int jj=128-8*dl_node0_start_offset; jj<8*(dl_node0_tr.data_byte_len%16); jj++)begin
                    if(dma_mem[2].exists(dl_node0_tr.des_addr+16*(ii+1)))begin
                        dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                    end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*(ii+1)))begin
                        dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                    end else begin
                        dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                    end
                end
                for(int jj=8*(dl_node0_tr.data_byte_len%16); jj<128; jj++)begin
                    dl_node0_pld.data[jj] = 'h0;
                end
            end else begin
                for(int jj=0; jj<8*(dl_node0_tr.data_byte_len%16); jj++)begin
                    if(dma_mem[2].exists(dl_node0_tr.des_addr+16*ii))begin
                        dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[2][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*ii))begin
                        dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[1][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end else begin
                        dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[0][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                    end
                end
                for(int jj=8*(dl_node0_tr.data_byte_len%16); jj<128; jj++)begin
                    dl_node0_pld.data[jj] = 'h0;
                end
            end
        end else begin
            for(int jj=0; jj<128-8*dl_node0_start_offset; jj++)begin
                if(dma_mem[2].exists(dl_node0_tr.des_addr+16*ii))begin
                    dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[2][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*ii))begin
                    dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[1][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                end else begin
                    dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*ii][127:64] == 'h0 ? dma_mem[0][dl_node0_tr.des_addr+16*ii+dl_node0_start_offset][jj+8*dl_node0_start_offset] : dma_mem[0][dl_node0_tr.des_addr+16*ii][jj+8*dl_node0_start_offset];
                end
            end
            for(int jj=128-8*dl_node0_start_offset; jj<128; jj++)begin
                if(dma_mem[2].exists(dl_node0_tr.des_addr+16*(ii+1)))begin
                    dl_node0_pld.data[jj] = dma_mem[2][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                end else if(dma_mem[1].exists(dl_node0_tr.des_addr+16*(ii+1)))begin                                                                                                                        
                    dl_node0_pld.data[jj] = dma_mem[1][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                end else begin                                                                                                                                                                             
                    dl_node0_pld.data[jj] = dma_mem[0][dl_node0_tr.des_addr+16*(ii+1)][jj+8*dl_node0_start_offset-128];
                end
            end
        end
        dl_node0_pld.stream_id = cfg.stream_id6;
        dl_node0_pld.addr = (ii == 0) ? dl_node0_tr.des_addr+dl_node0_start_offset : dl_node0_tr.des_addr+16*ii;
        mon_port.write(dl_node0_pld);
        //`uvm_info($sformatf("%25s", get_full_name()), $sformatf("test_debug: dl_node0_pld is \n%s", dl_node0_pld.sprint()), UVM_DEBUG)
    end
endtask : collect_dl_node0_pld_trans //}}} 

function void nr_l2dl_dtc_rdma_monitor::report_phase(uvm_phase phase); //{{{
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("\nReport: register database monitor collected %0d transfers", num_col), UVM_LOW)
endfunction : report_phase //}}}

`endif

