// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 16:37
// Filename     : nr_l2dl_base_vseq.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_BASE_VSEQ_SV
`define NR_L2DL_BASE_VSEQ_SV

class nr_l2dl_base_vseq extends uvm_sequence;
    virtual nr_l2dl_top_intf  m_nr_l2dl_top_vif;


    nr_l2dl_blkaddr_seq       m_blkaddr_seq;

    //nr_l2dl_apb_init_seq  m_nr_l2dl_apb_init_seq;
    //nr_l2dl_apb_reg_seq   m_nr_l2dl_apb_reg_seq;
    //nr_l2dl_apb_mem_seq   m_nr_l2dl_apb_mem_seq;

    nr_l2dl_env_cfg       m_nr_l2dl_env_cfg;
    //nr_l2dl_coverage      m_nr_l2dl_coverage;
    rx_mac_reg_cfg       m_rx_mac_reg_cfg;



    `uvm_declare_p_sequencer(nr_l2dl_vseqr)
    `uvm_object_utils(nr_l2dl_base_vseq)

    extern function new(string name = "nr_l2dl_base_vseq");
    extern virtual task pre_start();
    extern virtual task post_start();
    extern virtual task get_config();
    extern virtual task rand_dly(int max_dly_cyc=0);
    extern virtual task l2_blkaddr_proc();

endclass: nr_l2dl_base_vseq
 
function nr_l2dl_base_vseq::new(string name = "nr_l2dl_base_vseq");
    super.new(name);
endfunction: new

task nr_l2dl_base_vseq::pre_start();
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("pre_start begin"), UVM_MEDIUM)
    if(starting_phase!=null) begin
       starting_phase.raise_objection(this);
       `uvm_info($sformatf("%25s", get_full_name()), $sformatf("pre_start raise_objection"), UVM_MEDIUM)
    end
    get_config();


    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("pre_start end"), UVM_MEDIUM)
endtask : pre_start

task nr_l2dl_base_vseq::post_start();
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("post_start begin"), UVM_MEDIUM)
    if(starting_phase!=null) begin
       starting_phase.drop_objection(this);
       `uvm_info($sformatf("%25s", get_full_name()), $sformatf("post_start drop_objection"), UVM_MEDIUM)
    end
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("post_start end"), UVM_MEDIUM)
endtask : post_start


task nr_l2dl_base_vseq::get_config();

    if(!uvm_config_db #(nr_l2dl_env_cfg)::get(m_sequencer, "", "m_nr_l2dl_env_cfg", m_nr_l2dl_env_cfg)) begin
       `uvm_info($sformatf("%25s", m_sequencer.get_full_name()), $sformatf("Can not get cfg handle in nr_l2dl_base_vseq"), UVM_LOW)
    end

    //if(!uvm_config_db #(nr_l2dl_coverage)::get(m_sequencer, "", "m_nr_l2dl_coverage", m_nr_l2dl_coverage)) begin
    //   `uvm_info($sformatf("%25s", m_sequencer.get_full_name()), $sformatf("Can not get coverage handle in nr_l2dl_base_vseq"), UVM_LOW)
    //end

    if(!uvm_config_db #(virtual nr_l2dl_top_intf)::get(m_sequencer, "", "vif", m_nr_l2dl_top_vif)) begin
       `uvm_info($sformatf("%25s", m_sequencer.get_full_name()), $sformatf("Can not get top_vif handle in nr_l2dl_base_vseq"), UVM_LOW)
    end

    m_rx_mac_reg_cfg  = m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg;
endtask : get_config

task nr_l2dl_base_vseq::rand_dly(int max_dly_cyc=0);
    int dly_cyc;
    if(max_dly_cyc) begin
        if(std::randomize() with {dly_cyc dist {0:=5, [0:max_dly_cyc]:/3, max_dly_cyc:=2};}) begin
            repeat(dly_cyc) @(m_nr_l2dl_top_vif.moncb);    
        end
        else
            `uvm_error("IP.DBG", $sformatf("[nr_l2dl][%s randomize fail]", get_full_name()))
    end
endtask : rand_dly

task nr_l2dl_base_vseq::l2_blkaddr_proc();
    uvm_mem_region mem_region;
    regbus_item blkaddr_tr;
    int unsigned l2_blkaddr_fifo_start;
    int unsigned blkaddr_pool[$];
    int unsigned blkaddr_bk_pool[$];
    bit [31:0]   blk_fifo_addr=32'h800;
    for(int ii=0; ii<m_nr_l2dl_env_cfg.blkaddr_pool_size; ii++)begin
        blkaddr_pool.push_back(ii);
    end
    blkaddr_pool.shuffle();
    mem_region = m_nr_l2dl_env_cfg.ddr_mem.mam.request_region((1024*m_nr_l2dl_env_cfg.blkaddr_pool_size*(2**(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.blk_size+3))), m_nr_l2dl_env_cfg.ddr_mem_policy); 
    if(mem_region == null)begin
        `uvm_error(get_full_name(), $sformatf("fail to request %0d byte for blk addr fifo", 4*2*256))
        return;
    end
    l2_blkaddr_fifo_start = mem_region.get_start_offset() + m_nr_l2dl_env_cfg.ddr_mem_base;
    `uvm_info(get_full_name(), $sformatf("l2_blkaddr_fifo_start %h", l2_blkaddr_fifo_start), UVM_MEDIUM)
    blkaddr_tr = regbus_item::type_id::create("blkaddr_tr"); 
    fork
        forever begin
            int unsigned pool_idx_l;
            int unsigned pool_idx_h;
            `uvm_create_on(m_blkaddr_seq, p_sequencer.nr_l2dl_blkaddr_seqr)
            if(blkaddr_pool.size() == 0)
                `uvm_error(get_full_name(), $sformatf("there is no blkaddr_pool idx, should get more"))
            pool_idx_l = blkaddr_pool.pop_front();
            blkaddr_bk_pool.push_back(pool_idx_l);
            //if(blkaddr_pool.size()%3 == 2)begin
            //    pool_idx_h = blkaddr_pool.pop_front();
            //    blkaddr_bk_pool.push_back(pool_idx_h);
            //    assert(blkaddr_tr.randomize() with {
            //        iwdata[31:0] == l2_blkaddr_fifo_start+1024*pool_idx_l*(2**(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.blk_size+3));
            //        iwdata[63:32] == l2_blkaddr_fifo_start+1024*pool_idx_h*(2**(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.blk_size+3));
            //        iaddr == blk_fifo_addr;
            //        kind == WRITE_64;
            //        ilane == 2'h3;
            //    });
            //end else begin
                assert(blkaddr_tr.randomize() with {
                    //ilane inside {2'h1,2'h2};
                    ilane inside {2'h1};
                    if(ilane == 2'h1){
                        iwdata[63:32] == 32'h12345678;
                        iwdata[31:0] == l2_blkaddr_fifo_start+1024*pool_idx_l*(2**(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.blk_size+3));
                        kind == WRITE_32_L;
                    }else{
                        iwdata[31:0] == 32'h12345678;
                        iwdata[63:32] == l2_blkaddr_fifo_start+1024*pool_idx_l*(2**(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.blk_size+3));
                        kind == WRITE_32_H;
                    }
                    iaddr == blk_fifo_addr;
                    solve ilane before iwdata;
                });
            //end
            m_blkaddr_seq.tr_q=blkaddr_tr;
            @(posedge m_nr_l2dl_top_vif.clk iff (m_nr_l2dl_top_vif.blkaddr_fifo_freespace < 'hc0));
            `uvm_send(m_blkaddr_seq)
            //if(blk_fifo_addr == 'hff8)begin
            //    blk_fifo_addr = 'h800;
            //end else begin
            //    blk_fifo_addr = blk_fifo_addr + 'h8;
            //end
            `uvm_info(get_full_name(), $sformatf("Report : l2_blkaddr_proc done : \n%s", blkaddr_tr.sprint()), UVM_MEDIUM)
        end
        forever begin
            @(posedge m_nr_l2dl_top_vif.clk iff (m_nr_l2dl_top_vif.blkaddr_fifo_freespace >= 'h40));
            while(blkaddr_bk_pool.size() != 0)begin
                int unsigned pool_idx;
                pool_idx = blkaddr_bk_pool.pop_front();
                blkaddr_pool.push_back(pool_idx);
            end
        end
    join_none
endtask : l2_blkaddr_proc

`endif

