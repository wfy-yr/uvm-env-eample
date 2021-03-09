class nr_l2dl_ref_model extends uvm_component;
    virtual nr_l2dl_top_intf top_vif;

    nr_l2dl_env_cfg     m_nr_l2dl_env_cfg;
    rx_mac_reg_cfg     m_rx_mac_reg_cfg;
    
    uvm_tlm_analysis_fifo #(nr_l2dl_fifo_trans) tb_cmd_fifo_port;

    uvm_tlm_analysis_fifo #(rx_mac_l1_tb_info) l1_tb_info_buffer;
    uvm_tlm_analysis_fifo #(rx_mac_l2_tb_info) l2_tb_info_buffer;

    //expect port to scb
    uvm_analysis_port#(nr_l2dl_fifo_trans)      exp_ap;

    nr_l2dl_mce_cfg     mce_cfg[31];
    
    `uvm_component_utils(nr_l2dl_ref_model)

    extern function new(input string name, input uvm_component parent=null);

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);


    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void read_memory(input int data_len, input bit [31:0] addr, ref bit bit_stream[]);
    extern virtual task get_tb_info_data();
    extern virtual task mce_l1_chk();
    extern virtual task l2_chk();
endclass : nr_l2dl_ref_model 


function nr_l2dl_ref_model::new(input string name, input uvm_component parent=null);
    super.new(name,parent);
    tb_cmd_fifo_port = new("tb_cmd_fifo_port", this); 
    l1_tb_info_buffer = new("l1_tb_info_buffer", this); 
    l2_tb_info_buffer = new("l2_tb_info_buffer", this); 

    exp_ap = new("exp_ap", this); 
endfunction : new

function void nr_l2dl_ref_model::build_phase(uvm_phase phase); // {{{
    super.build_phase(phase);

    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase begin"), UVM_LOW)
    
    if(!uvm_config_db#(virtual nr_l2dl_top_intf)::get(this, "", "vif", top_vif)) begin
        `uvm_fatal("NOCFG", $sformatf("[%s] Cannot get nr_l2dl_top_vif", get_full_name()))
    end      


    if(!uvm_config_db#(nr_l2dl_env_cfg)::get(this, "", "m_nr_l2dl_env_cfg", m_nr_l2dl_env_cfg)) begin
        `uvm_fatal("NOCFG", $sformatf("[%s] Cannot get nr_l2dl_env_cfg", get_full_name()))
    end      

    m_rx_mac_reg_cfg =  m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg;

    foreach(mce_cfg[ii]) begin
        mce_cfg[ii] = nr_l2dl_mce_cfg::type_id::create($sformatf("mce_cfg[%0d]", ii));
    end
    

    `uvm_info($sformatf("%25s", get_name()), $sformatf("build_phase end"), UVM_LOW)
endfunction : build_phase // }}}


function void nr_l2dl_ref_model::connect_phase(uvm_phase phase); // {{{
    super.connect_phase(phase);
endfunction : connect_phase // }}}


task nr_l2dl_ref_model::run_phase(uvm_phase phase); // {{{
    fork
        get_tb_info_data(); 
        mce_l1_chk();
        l2_chk();
    join_none
endtask : run_phase // }}}

function void nr_l2dl_ref_model::read_memory(input int data_len, input bit [31:0] addr, ref bit bit_stream[]);
    for(int ii=addr; ii<addr+data_len; ii++) begin
        for(int jj=0; jj<=7; jj++) begin
            bit_stream[jj+8*(ii-addr)] = m_nr_l2dl_env_cfg.memory[ii][jj];
        end
    end
endfunction : read_memory 


task nr_l2dl_ref_model::get_tb_info_data(); // {{{
    nr_l2dl_fifo_trans           fifo_tr;
    rx_mac_tb_cmd_trans          tb_cmd_tr;
    rx_mac_l1_tb_info           l1_tb_info;
    rx_mac_l2_tb_info           l2_tb_info;
    nr_l2dl_dtc_pld_trans       exp_dtc_pld;


    bit pload_data[];
    bit bit_stream[];
    int bit_num; 
    bit [6:0]  tb_idx;    
    forever begin
        tb_cmd_fifo_port.get(fifo_tr);
        assert($cast(tb_cmd_tr,fifo_tr));
        tb_idx=top_vif.l2mac_tag[6:0]; 
        `uvm_info(get_full_name(), $sformatf("read tb[%0d]_tb_cmd:\n%s",tb_idx,tb_cmd_tr.sprint()),UVM_MEDIUM)
        begin
            if(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.tb_dbgout_en == 1'h1)begin
                for(int jj=0; jj<m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len/16; jj++) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(16,m_nr_l2dl_env_cfg.dbg_out_addr+(tb_idx-`TB_IDX)*m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len+jj*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = m_nr_l2dl_env_cfg.dbg_out_addr+(tb_idx-`TB_IDX)*m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len+jj*16;
                    exp_ap.write(exp_dtc_pld);
                end
                if(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len%16>0) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len%16,m_nr_l2dl_env_cfg.dbg_out_addr+(tb_idx-`TB_IDX)*m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len+(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len/16)*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = m_nr_l2dl_env_cfg.dbg_out_addr+(tb_idx-`TB_IDX)*m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len+(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len/16)*16;
                    exp_ap.write(exp_dtc_pld);
                end
            end
        end

        begin
            bit_stream=new[128];
            read_memory(16,m_nr_l2dl_env_cfg.tb_info1_dma_addr+(tb_idx-`TB_IDX)*16,bit_stream);
            l1_tb_info = rx_mac_l1_tb_info::type_id::create("l1_tb_info", this);
            void'(l1_tb_info.unpack(bit_stream, default_packer));
            bit_stream.delete(); 
            //assert((l1_tb_info.harqid == tb_cmd_tr.harqid)&&
            assert((l1_tb_info.cellgroup == tb_cmd_tr.cellgroup)&&
                   (l1_tb_info.cellindex == tb_cmd_tr.cellindex)&&
                   (l1_tb_info.cursfn == tb_cmd_tr.sfn)&&
                   (l1_tb_info.cursubsfn == tb_cmd_tr.subsfn)&&
                   (l1_tb_info.scs == tb_cmd_tr.scs)) else
                `uvm_error(get_full_name(), $sformatf("read l1 tb_info is error \ntb_cmd_tr:\n%s \nl1_tb_info:\n%s",tb_cmd_tr.sprint(),l1_tb_info.sprint()))
           l1_tb_info_buffer.put(l1_tb_info); 
           //l1_tb_info.stream_id = DMA_L1_TB_INFO;
           //exp_ap.write(l1_tb_info);
           l1_tb_info.stream_id = TB_INFO1_DMA;
           exp_ap.write(l1_tb_info);
           `uvm_info(get_full_name(), $sformatf("read tb[%0d]_l1_tb_info:\n%s",tb_idx,l1_tb_info.sprint()),UVM_MEDIUM)
        end

        begin
            bit_stream=new[256];
            read_memory(32,m_nr_l2dl_env_cfg.tb_info2_dma_addr+(tb_idx-`TB_IDX)*32,bit_stream);
            l2_tb_info = rx_mac_l2_tb_info::type_id::create("l2_tb_info", this);
            void'(l2_tb_info.unpack(bit_stream, default_packer));
            bit_stream.delete(); 
            //assert((l2_tb_info.harqid == tb_cmd_tr.harqid)&&
            assert((l2_tb_info.cellgroup == tb_cmd_tr.cellgroup)&&
                   (l2_tb_info.cellindex == tb_cmd_tr.cellindex)&&
                   (l2_tb_info.cursfn == tb_cmd_tr.sfn)&&
                   (l2_tb_info.cursubsfn == tb_cmd_tr.subsfn)&&
                   (l2_tb_info.scs == tb_cmd_tr.scs)) else
                `uvm_error(get_full_name(), $sformatf("read l2 tb_info is error \ntb_cmd_tr:\n%s \nl2_tb_info:\n%s",tb_cmd_tr.sprint(),l2_tb_info.sprint()))
           l2_tb_info_buffer.put(l2_tb_info); 
           //l2_tb_info.stream_id = DMA_L2_TB_INFO;
           //exp_ap.write(l2_tb_info);
           l2_tb_info.stream_id = TB_INFO2_DMA;
           exp_ap.write(l2_tb_info);
           `uvm_info(get_full_name(), $sformatf("read tb[%0d]_l2_tb_info:\n%s",tb_idx,l2_tb_info.sprint()),UVM_MEDIUM)
        end
    end
endtask : get_tb_info_data // }}}

task nr_l2dl_ref_model::mce_l1_chk();
    rx_mac_l1_tb_info           l1_tb_info;
    rx_mac_mce_node             exp_l1_mce_node;
    nr_l2dl_dtc_pld_trans       exp_dtc_pld,exp_dma_pld;


    bit bit_stream[];
    bit pload_data[];
    forever begin
        l1_tb_info_buffer.get(l1_tb_info); 
        if((l1_tb_info.mce_node_num > 0) && (m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_bits != 16'hffff) && (m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_en ==1)) begin
            for(int ii=0; ii<l1_tb_info.mce_node_num; ii++) begin
                bit_stream=new[64];
                read_memory(8,m_nr_l2dl_env_cfg.macce_node1_dma_addr+8*l1_tb_info.first_mce_node_idx+ii*8,bit_stream);
                exp_l1_mce_node = rx_mac_mce_node::type_id::create("exp_l1_mce_node", this);
                void'(exp_l1_mce_node.unpack(bit_stream, default_packer));
                //exp_l1_mce_node.stream_id = DMA_L1_MCE_NODE;
                //exp_ap.write(exp_l1_mce_node);
                exp_l1_mce_node.stream_id = MCE_NODE1_DMA;
                exp_ap.write(exp_l1_mce_node);
                for(int jj=0; jj<exp_l1_mce_node.l/16; jj++) begin
                    //`uvm_info(get_full_name(), $sformatf("jj=%0d",jj),UVM_MEDIUM)
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(16,exp_l1_mce_node.mce_start_addr+jj*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = exp_l1_mce_node.mce_start_addr+jj*16;
                    exp_ap.write(exp_dtc_pld);
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //exp_dma_pld.stream_id = DMA_L1_MCE_PLD;
                    //exp_ap.write(exp_dma_pld);
                    exp_dma_pld.stream_id = MCE_PLD_DMA;
                    exp_ap.write(exp_dma_pld);
                end
                if(exp_l1_mce_node.l%16>0) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(exp_l1_mce_node.l%16,exp_l1_mce_node.mce_start_addr+(exp_l1_mce_node.l/16)*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = exp_l1_mce_node.mce_start_addr+(exp_l1_mce_node.l/16)*16;
                    exp_ap.write(exp_dtc_pld);
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //exp_dma_pld.stream_id = DMA_L1_MCE_PLD;
                    //exp_ap.write(exp_dma_pld);
                    exp_dma_pld.stream_id = MCE_PLD_DMA;
                    exp_ap.write(exp_dma_pld);
                end
                else if((m_nr_l2dl_env_cfg.mce_cfg[(exp_l1_mce_node.lcid) - 33].length>0)&&(exp_l1_mce_node.l == 'h0)) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(m_nr_l2dl_env_cfg.mce_cfg[(exp_l1_mce_node.lcid) - 33].length%16,exp_l1_mce_node.mce_start_addr+(m_nr_l2dl_env_cfg.mce_cfg[(exp_l1_mce_node.lcid) - 33].length/16)*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = exp_l1_mce_node.mce_start_addr+(m_nr_l2dl_env_cfg.mce_cfg[(exp_l1_mce_node.lcid) - 33].length/16)*16;
                    exp_ap.write(exp_dtc_pld);
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //exp_dma_pld.stream_id = DMA_L1_MCE_PLD;
                    //exp_ap.write(exp_dma_pld);
                    exp_dma_pld.stream_id = MCE_PLD_DMA;
                    exp_ap.write(exp_dma_pld);
                end
            end
        end
    end
endtask : mce_l1_chk 

task nr_l2dl_ref_model::l2_chk();
    rx_mac_l2_tb_info           l2_tb_info;
    rx_mac_mce_node             exp_l2_mce_node;
    rx_mac_dl_node0             exp_dl_node0;
    nr_l2dl_dtc_pld_trans       exp_dtc_pld,exp_dma_pld;
    rx_mac_acc_node             exp_acc_node;

    bit bit_stream[];
    bit pload_data[];
    forever begin
        l2_tb_info_buffer.get(l2_tb_info); 
        if((l2_tb_info.mce_node_num > 0) && (m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_bits != 16'h0) && (m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_en ==1)) begin
            for(int ii=0; ii<l2_tb_info.mce_node_num; ii++) begin
                bit_stream=new[64];
                read_memory(8,m_nr_l2dl_env_cfg.macce_node2_dma_addr+8*l2_tb_info.first_mce_node_idx+ii*8,bit_stream);
                exp_l2_mce_node = rx_mac_mce_node::type_id::create("exp_l2_mce_node", this);
                void'(exp_l2_mce_node.unpack(bit_stream, default_packer));
                //exp_l2_mce_node.stream_id = DMA_L2_MCE_NODE;
                //exp_ap.write(exp_l2_mce_node);
                exp_l2_mce_node.stream_id = MCE_NODE2_DMA;
                exp_ap.write(exp_l2_mce_node);
                for(int jj=0; jj<exp_l2_mce_node.l/16; jj++) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(16,exp_l2_mce_node.mce_start_addr+jj*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = exp_l2_mce_node.mce_start_addr+jj*16;
                    exp_ap.write(exp_dtc_pld);
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //exp_dma_pld.stream_id = DMA_L2_MCE_PLD;
                    //exp_ap.write(exp_dma_pld);
                    exp_dma_pld.stream_id = MCE_PLD_DMA;
                    exp_ap.write(exp_dma_pld);
                end
                if(exp_l2_mce_node.l%16>0) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(exp_l2_mce_node.l%16,exp_l2_mce_node.mce_start_addr+(exp_l2_mce_node.l/16)*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = exp_l2_mce_node.mce_start_addr+(exp_l2_mce_node.l/16)*16;
                    exp_ap.write(exp_dtc_pld);
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //exp_dma_pld.stream_id = DMA_L2_MCE_PLD;
                    //exp_ap.write(exp_dma_pld);
                    exp_dma_pld.stream_id = MCE_PLD_DMA;
                    exp_ap.write(exp_dma_pld);
                end
                else if((m_nr_l2dl_env_cfg.mce_cfg[(exp_l2_mce_node.lcid) - 33].length>0)&&(exp_l2_mce_node.l == 'h0)) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    read_memory(m_nr_l2dl_env_cfg.mce_cfg[(exp_l2_mce_node.lcid) - 33].length%16,exp_l2_mce_node.mce_start_addr+(m_nr_l2dl_env_cfg.mce_cfg[(exp_l2_mce_node.lcid) - 33].length/16)*16,pload_data);
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    exp_dtc_pld.addr = exp_l2_mce_node.mce_start_addr+(m_nr_l2dl_env_cfg.mce_cfg[(exp_l2_mce_node.lcid) - 33].length/16)*16;
                    exp_ap.write(exp_dtc_pld);
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //exp_dma_pld.stream_id = DMA_L2_MCE_PLD;
                    //exp_ap.write(exp_dma_pld);
                    exp_dma_pld.stream_id = MCE_PLD_DMA;
                    exp_ap.write(exp_dma_pld);
                end
            end
        end
        if(l2_tb_info.nr_l2_acc_num > 0) begin
            for(int ii=0; ii<l2_tb_info.nr_l2_acc_num; ii++) begin
                bit_stream=new[128];
                read_memory(16,m_nr_l2dl_env_cfg.acc_node_dma_addr+16*l2_tb_info.first_l2_acc_idx+ii*16,bit_stream);
                exp_acc_node = rx_mac_acc_node::type_id::create("exp_acc_node", this);
                void'(exp_acc_node.unpack(bit_stream, default_packer));
                if(exp_acc_node.lcid != 'h3f) begin
                    if(m_nr_l2dl_env_cfg.lc_cfg[exp_acc_node.lcid].lgch_active == nr_l2dl_lc_cfg::LGCH_ACTIVE) begin
                        //exp_acc_node.stream_id = DMA_ACC_NODE;
                        //exp_ap.write(exp_acc_node);
                        exp_acc_node.stream_id = ACC_NODE_DMA;
                        exp_ap.write(exp_acc_node);
                    end
                end else begin
                    exp_acc_node.stream_id = ACC_NODE_DMA;
                    exp_ap.write(exp_acc_node);
                end
            end
        end
        if(l2_tb_info.l2dl_node_num > 0) begin
            for(int ii=0; ii<l2_tb_info.l2dl_node_num; ii++) begin
                bit_stream=new[256];
                read_memory(32,m_nr_l2dl_env_cfg.dl_node0_dma_addr+32*l2_tb_info.first_l2dl_node_out_idx+ii*32,bit_stream);
                exp_dl_node0 = rx_mac_dl_node0::type_id::create("exp_dl_node0", this);
                void'(exp_dl_node0.unpack(bit_stream, default_packer));
                if(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].lgch_active == nr_l2dl_lc_cfg::LGCH_ACTIVE) begin
                    //exp_dl_node0.stream_id = DMA_DL_NODE0;
                    //exp_ap.write(exp_dl_node0);
                    exp_dl_node0.stream_id = DL_NODE0_DMA;
                    exp_ap.write(exp_dl_node0);
                    exp_dl_node0.stream_id = DL_NODE0_ACC;
                    exp_ap.write(exp_dl_node0);
                end
                for(int jj=0; jj<exp_dl_node0.data_byte_len/16; jj++) begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    if(exp_dl_node0.assemble_success == 'h1) begin
                        read_memory(16,exp_dl_node0.des_addr+jj*16,pload_data);
                    end else begin
                        read_memory(16,exp_dl_node0.des_addr+jj*16+exp_dl_node0.so,pload_data);
                    end
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    if(exp_dl_node0.assemble_success == 'h1) begin
                        exp_dtc_pld.addr = exp_dl_node0.des_addr+jj*16;
                    end else begin
                        exp_dtc_pld.addr = exp_dl_node0.des_addr+jj*16+exp_dl_node0.so;
                    end
                    //if((exp_dl_node0.assemble_success == 'h1) || (m_rx_mac_reg_cfg.asmb_seg_type == 'h0) || (exp_dl_node0.si == 'h0) || ((m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)))begin 
                    if(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].lgch_active == nr_l2dl_lc_cfg::LGCH_ACTIVE) begin
                        exp_ap.write(exp_dtc_pld);
                    end
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //if((exp_dl_node0.assemble_success == 'h1) || (m_rx_mac_reg_cfg.asmb_seg_type == 'h0) || (exp_dl_node0.si == 'h0) || ((m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)))begin 
                    if(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].lgch_active == nr_l2dl_lc_cfg::LGCH_ACTIVE) begin
                        //exp_dma_pld.stream_id = DMA_DL_NODE0_PLD;
                        //exp_ap.write(exp_dma_pld);
                        exp_dma_pld.stream_id = DL_NODE0_PLD_DMA;
                        exp_ap.write(exp_dma_pld);
                    end
                end
                if(exp_dl_node0.data_byte_len%16>0)begin
                    pload_data=new[128];
                    exp_dtc_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dtc_pld", this);
                    if(exp_dl_node0.assemble_success == 'h1) begin
                        read_memory(exp_dl_node0.data_byte_len%16,exp_dl_node0.des_addr+(exp_dl_node0.data_byte_len/16)*16,pload_data);
                    end else begin
                        read_memory(exp_dl_node0.data_byte_len%16,exp_dl_node0.des_addr+exp_dl_node0.so+(exp_dl_node0.data_byte_len/16)*16,pload_data);
                    end
                    exp_dtc_pld.stream_id = DTC_PLD;
                    foreach(pload_data[ii])begin
                        exp_dtc_pld.data[ii] = pload_data[ii];
                    end
                    if(exp_dl_node0.assemble_success == 'h1) begin
                        exp_dtc_pld.addr = exp_dl_node0.des_addr+(exp_dl_node0.data_byte_len/16)*16;
                    end else begin
                        exp_dtc_pld.addr = exp_dl_node0.des_addr+exp_dl_node0.so+(exp_dl_node0.data_byte_len/16)*16;
                    end
                    //if((exp_dl_node0.assemble_success == 'h1) || (m_rx_mac_reg_cfg.asmb_seg_type == 'h0) || (exp_dl_node0.si == 'h0) || ((m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)))begin 
                    if(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].lgch_active == nr_l2dl_lc_cfg::LGCH_ACTIVE) begin
                        exp_ap.write(exp_dtc_pld);
                    end
                    //check dma pload data
                    exp_dma_pld = nr_l2dl_dtc_pld_trans::type_id::create("exp_dma_pld", this);
                    exp_dma_pld.data = exp_dtc_pld.data;
                    exp_dma_pld.addr = exp_dtc_pld.addr;
                    //if((exp_dl_node0.assemble_success == 'h1) || (m_rx_mac_reg_cfg.asmb_seg_type == 'h0) || (exp_dl_node0.si == 'h0) || ((m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)))begin 
                    if(m_nr_l2dl_env_cfg.lc_cfg[exp_dl_node0.lcid].lgch_active == nr_l2dl_lc_cfg::LGCH_ACTIVE) begin
                        //exp_dma_pld.stream_id = DMA_DL_NODE0_PLD;
                        //exp_ap.write(exp_dma_pld);
                        exp_dma_pld.stream_id = DL_NODE0_PLD_DMA;
                        exp_ap.write(exp_dma_pld);
                    end
                end
            end
        end
    end
endtask : l2_chk 
