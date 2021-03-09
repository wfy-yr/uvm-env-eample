// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 16:37
// Filename     : nr_l2dl_all_pkt_vseq.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_ALL_PKT_VSEQ_SV
`define NR_L2DL_ALL_PKT_VSEQ_SV

class nr_l2dl_all_pkt_vseq extends nr_l2dl_base_vseq;

   nr_l2dl_init_regbus_seq   m_regbus_reset_sequence;
   nr_l2dl_init_seq          m_nr_l2dl_init_seq;
   nr_l2dl_tb_cmd_seq        m_nr_l2dl_tb_cmd_seq;
   nr_l2dl_l1_cfg_seq        m_nr_l2dl_l1_cfg_seq;
   nr_l2dl_l2_cfg_seq        m_nr_l2dl_l2_cfg_seq;
    
   rand rx_mac_dl_node0_pkt_cfg  normal_pkt_cfg[200];


   `uvm_object_utils(nr_l2dl_all_pkt_vseq)

   extern function new(string name = "nr_l2dl_all_pkt_vseq");
   extern virtual task body();
   extern virtual task init_l1l2_reg_cfg();
   extern virtual task l2_reg_cfg();

endclass: nr_l2dl_all_pkt_vseq
 
function nr_l2dl_all_pkt_vseq::new(string name = "nr_l2dl_all_pkt_vseq");
        super.new(name);
endfunction: new

task nr_l2dl_all_pkt_vseq::body();
    int tb_cnt=`TB_IDX;
    rx_mac_tb_cmd_trans  tb_cmd_trans; 
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("body begin"), UVM_MEDIUM)
    fork
        `uvm_do_on(m_regbus_reset_sequence, p_sequencer.m_l1_cfg_seqr)
        `uvm_do_on(m_regbus_reset_sequence, p_sequencer.m_l2_cfg_seqr)
    join
    repeat(100) @(posedge m_nr_l2dl_top_vif.clk);
    init_l1l2_reg_cfg();
    fork
        forever begin
            tb_cmd_trans = rx_mac_tb_cmd_trans::type_id::create("tb_cmd_trans");
            @(posedge m_nr_l2dl_top_vif.clk iff m_nr_l2dl_top_vif.l2mac_req == 'b1);
            assert(tb_cmd_trans.randomize() with {tb_size == m_nr_l2dl_env_cfg.tb_size[m_nr_l2dl_top_vif.l2mac_tag[6:0]]; 
                                                  //harqid== m_nr_l2dl_env_cfg.harqid;
                                                  cellgroup == m_nr_l2dl_env_cfg.cellgroup;
                                                  cellindex == m_nr_l2dl_env_cfg.cellindex;
                                                  sfn == m_nr_l2dl_env_cfg.cursfn;
                                                  subsfn == m_nr_l2dl_env_cfg.cursubsfn;
                                                  scs == m_nr_l2dl_env_cfg.scs;});
            `uvm_create_on(m_nr_l2dl_tb_cmd_seq, p_sequencer.m_nr_l2dl_tb_cmd_seqr)
            m_nr_l2dl_tb_cmd_seq.tr_q = tb_cmd_trans;
            `uvm_send(m_nr_l2dl_tb_cmd_seq);
        end
    join_none
    l2_reg_cfg();
    l2_blkaddr_proc();
    begin
        @(posedge m_nr_l2dl_top_vif.clk iff m_nr_l2dl_top_vif.l2_ready == 'b1);
        repeat(`TB_NUM) begin
            @(posedge m_nr_l2dl_top_vif.clk);
            m_nr_l2dl_top_vif.l2_trig    <= 1'b1;
            m_nr_l2dl_top_vif.l2_tag[6:0]      <= tb_cnt;
            m_nr_l2dl_top_vif.l2_tag[11:7]     <= m_nr_l2dl_env_cfg.harqid;
            tb_cnt++;
        end
        @(posedge m_nr_l2dl_top_vif.clk);
        m_nr_l2dl_top_vif.l2_trig    <= 'h0;
        m_nr_l2dl_top_vif.l2_tag     <= 'h0;
    end
    repeat(`TB_NUM) begin
        @(posedge m_nr_l2dl_top_vif.clk iff m_nr_l2dl_top_vif.dtc_tb_int == 'b1);
        //m_nr_l2dl_l1_cfg_seq.write_l1_cfg();
        //m_nr_l2dl_l2_cfg_seq.write_glb_cfg();
        //repeat(5) @(posedge m_nr_l2dl_top_vif.clk);
        //m_nr_l2dl_l1_cfg_seq.read_l1_cfg();
        //m_nr_l2dl_l2_cfg_seq.read_glb_cfg();
    end
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("body end"), UVM_MEDIUM)
endtask : body

task nr_l2dl_all_pkt_vseq::init_l1l2_reg_cfg();
    `uvm_do_on(m_nr_l2dl_l1_cfg_seq, p_sequencer.m_l1_cfg_seqr)
    `uvm_do_on(m_nr_l2dl_l2_cfg_seq, p_sequencer.m_l2_cfg_seqr)
endtask : init_l1l2_reg_cfg 

task nr_l2dl_all_pkt_vseq::l2_reg_cfg();
    //l2 glb reg
    assert(m_nr_l2dl_env_cfg.randomize() with{
        foreach(lc_cfg[ii]) {
            lc_cfg[ii].lgch_active == nr_l2dl_lc_cfg::LGCH_ACTIVE; 
            lc_cfg[ii].sft_dtc == nr_l2dl_lc_cfg::SFT_DTC; 
            if(lc_cfg[ii].rlc_mode == nr_l2dl_lc_cfg::RLC_AM){
                lc_cfg[ii].rlc_sn_len inside {nr_l2dl_lc_cfg::RLC_SN_12,nr_l2dl_lc_cfg::RLC_SN_18};
            }
            else if(lc_cfg[ii].rlc_mode == nr_l2dl_lc_cfg::RLC_UM){
                lc_cfg[ii].rlc_sn_len inside {nr_l2dl_lc_cfg::RLC_SN_6,nr_l2dl_lc_cfg::RLC_SN_12};
            }
            if(lc_cfg[ii].rb_type == nr_l2dl_lc_cfg::SRB){
                lc_cfg[ii].pdcp_sn_len inside {nr_l2dl_lc_cfg::PDCP_SN_12};
            }
            //if(ii==0){
            //    lc_cfg[ii].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT; 
            //    lc_cfg[ii].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT;
            //    lc_cfg[ii].rlc_mode inside {nr_l2dl_lc_cfg::RLC_AM,nr_l2dl_lc_cfg::RLC_UM};
            //}else if(ii==1){
            //    lc_cfg[ii].rb_type == nr_l2dl_lc_cfg::DRB;
            //    lc_cfg[ii].sdap_hdr_present == nr_l2dl_lc_cfg::NO_HDR;//TODO
            //    lc_cfg[ii].rlc_mode inside {nr_l2dl_lc_cfg::RLC_AM,nr_l2dl_lc_cfg::RLC_UM};
            //}
            if(lc_cfg[ii].cp_header_en == 'h1){
                lc_cfg[ii].resvd_intv_size[3:0]==4'h8;
            }else{
                lc_cfg[ii].resvd_intv_size inside {0,['h8:'hff]};
            }
        }
        foreach(key_enc[ii]) {
            key_enc[ii] == {32'h977dd4bf,32'had4b9bc1,32'h05071758,32'h648df8fa};
        }
        foreach(key_int[ii]) {
            key_int[ii] == {32'h977dd4bf,32'had4b9bc1,32'h05071758,32'h648df8fa};
        }
        //foreach(rx_deliv[ii]) {
        //    if(lc_cfg[ii].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12){
        //        rx_deliv[ii] inside {[0:((2**12)/2 - 'h1)]};
        //    }else if(lc_cfg[ii].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_18){
        //        rx_deliv[ii] inside {[0:((2**18)/2 - 'h1)]};
        //    }
        //}
        mce_num == 10;
        normal_node_num == 60;
        err_num == 0;
        padding_num == 0;

        continuous_data_num == 1;
        m_rx_mac_reg_cfg.dbg_out_len          ==  16'h8;
        m_rx_mac_reg_cfg.tb_dbgout_en         ==   1'h0; //TODO 
        m_rx_mac_reg_cfg.rxmac_work_en        ==   1'h1;
        m_rx_mac_reg_cfg.seg_buf_size         ==   6'h20;
        m_rx_mac_reg_cfg.asmb_seg_type inside {2'h1,2'h0};
        m_rx_mac_reg_cfg.macce_dec_en         ==   1'h1;
        m_rx_mac_reg_cfg.macce_dec_bits inside {16'h0,16'hffff}; //bit0~bit15:LCID=47~LCID62; 0:output to L1MacCeOutBase,1:output to L2MacCeOutBase
        m_rx_mac_reg_cfg.blk_size inside {2'h0,2'h1,2'h2,2'h3}; //0:8KB 1:16KB 2:32KB 3:64KB
        m_rx_mac_reg_cfg.lgch_cfg_done        ==   1'h1;
    });
    m_nr_l2dl_env_cfg.m_rx_mac_env_cfg.m_rx_mac_reg_cfg.macce_dec_en   = m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_en;
    m_nr_l2dl_env_cfg.m_rx_mac_env_cfg.m_rx_mac_reg_cfg.macce_dec_bits = m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_bits;
    for(int ii=0; ii<m_nr_l2dl_env_cfg.normal_node_num; ii++)begin
        normal_pkt_cfg[ii] = rx_mac_dl_node0_pkt_cfg::type_id::create($sformatf("normal_pkt_cfg[%0d]", ii));
        assert(normal_pkt_cfg[ii].randomize() with {
            lcid inside {[0:32]};
            seg_num == `TB_NUM;
            if(m_nr_l2dl_env_cfg.lc_cfg[lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_TM){
                rlc_sn == 'h0;
                polling == 'h0;
                pkt_type inside {rx_mac_dl_node0_pkt_cfg::RLC_TMD};
            }else if(m_nr_l2dl_env_cfg.lc_cfg[lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_AM){
                if((m_nr_l2dl_env_cfg.lc_cfg[lcid].rb_type == nr_l2dl_lc_cfg::DRB)&&(m_nr_l2dl_env_cfg.lc_cfg[lcid].sdap_hdr_present == nr_l2dl_lc_cfg::NO_HDR)){
                    if((m_nr_l2dl_env_cfg.lc_cfg[lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)){
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA,rx_mac_dl_node0_pkt_cfg::RLC_SEG,rx_mac_dl_node0_pkt_cfg::RLC_CTRL,rx_mac_dl_node0_pkt_cfg::PDCP_CTRL};
                    }else{
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA,rx_mac_dl_node0_pkt_cfg::RLC_CTRL,rx_mac_dl_node0_pkt_cfg::PDCP_CTRL};
                    }
                }else{
                    if((m_nr_l2dl_env_cfg.lc_cfg[lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)){
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA,rx_mac_dl_node0_pkt_cfg::RLC_SEG,rx_mac_dl_node0_pkt_cfg::RLC_CTRL};
                    }else{
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA,rx_mac_dl_node0_pkt_cfg::RLC_CTRL};
                    }
                }
                if((pkt_type == rx_mac_dl_node0_pkt_cfg::SDAP_DATA) || (pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG)){
                    rlc_sn == ii;
                    polling inside {'h0,'h1};
                }else{
                    rlc_sn == 'h0;
                    polling == 'h0;
                }
            }else if(m_nr_l2dl_env_cfg.lc_cfg[lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_UM){
                if((m_nr_l2dl_env_cfg.lc_cfg[lcid].rb_type == nr_l2dl_lc_cfg::DRB)&&(m_nr_l2dl_env_cfg.lc_cfg[lcid].sdap_hdr_present == nr_l2dl_lc_cfg::NO_HDR)){
                    if((m_nr_l2dl_env_cfg.lc_cfg[lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)){
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA,rx_mac_dl_node0_pkt_cfg::RLC_SEG,rx_mac_dl_node0_pkt_cfg::PDCP_CTRL};
                    }else{
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA,rx_mac_dl_node0_pkt_cfg::PDCP_CTRL};
                    }
                }else{
                    if((m_nr_l2dl_env_cfg.lc_cfg[lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_NO_PRESENT)&&(m_nr_l2dl_env_cfg.lc_cfg[lcid].cip_present == nr_l2dl_lc_cfg::CIP_NO_PRESENT)){
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA,rx_mac_dl_node0_pkt_cfg::RLC_SEG};
                    }else{
                        pkt_type inside {rx_mac_dl_node0_pkt_cfg::SDAP_DATA};
                    }
                }
                polling == 'h0;
                if(pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG){
                    rlc_sn == ii;
                }else{
                    rlc_sn == 'h0;
                }
            }
            pdcp_sn == rlc_sn;
            solve lcid before pkt_type;
            solve pkt_type before rlc_sn;
            solve pkt_type before polling;
        });
        normal_pkt_cfg[ii].rlc_sn = normal_pkt_cfg[ii].rlc_sn & m_nr_l2dl_env_cfg.lc_cfg[normal_pkt_cfg[ii].lcid].rlc_sn_modulo_mask; 
        normal_pkt_cfg[ii].pdcp_sn = normal_pkt_cfg[ii].pdcp_sn & m_nr_l2dl_env_cfg.lc_cfg[normal_pkt_cfg[ii].lcid].pdcp_sn_modulo_mask; 
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("normal_pkt_cfg[%0d] is \n%s",ii,normal_pkt_cfg[ii].sprint()), UVM_MEDIUM)
    end
    foreach(normal_pkt_cfg[ii]) begin
        m_nr_l2dl_env_cfg.normal_pkt_cfg[ii] = normal_pkt_cfg[ii];
    end
    `uvm_do_on(m_nr_l2dl_init_seq, p_sequencer.m_l2_cfg_seqr)
    m_nr_l2dl_top_vif.padding_flag = 1'b0;
endtask : l2_reg_cfg

//
`endif

