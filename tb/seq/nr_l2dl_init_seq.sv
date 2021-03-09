// =========================================================================== //
// Author       : fengyang.wu - ASR
// Last modified: 2020-07-10 11:00
// Filename     : nr_l2dl_init_seq.sv
// Description  : 
// =========================================================================== //
`ifndef NR_L2DL_INIT_SEQ_SV
`define NR_L2DL_INIT_SEQ_SV

//import "DPI-C" task main_rx_mac(input NrL2RegConfig L2RegConfig);

class nr_l2dl_init_seq extends nr_l2dl_base_seq;
   `uvm_object_utils(nr_l2dl_init_seq)
   //id gen parameter
   bit  [5:0] mce_fixed_lcid_q[$], mce_nonfixed_lcid_q[$];

   NrL2RegConfig  m_nr_l2_reg_cfg;
   //pdu pkt gen parameter
   rand nr_l2dl_mac_pkt      mac_pkt;
   rand nr_l2dl_rlc_pkt      rlc_pkt;
   rand nr_l2dl_pdcp_pkt     pdcp_pkt;
   rand nr_l2dl_sdap_pkt     sdap_pkt;
   rand nr_l2dl_pld_pkt      pload_pkt;

   rx_mac_l1_tb_info          l1_tb_info;
   rx_mac_l2_tb_info          l2_tb_info;
   rx_mac_mce_node            mce_node;
   rx_mac_dl_node0            dl_node0;
   rx_mac_dl_node0            exp_dl_node0;
   rx_mac_dl_node1            dl_node1;
   rx_mac_acc_node            acc_node,acc_node_tr_q[$];

   rx_mac_seg_pkt_info        seg_pkt_pool[`RX_MAC_ENTITY_NUM][int unsigned][$];
   int  dl_node0_length[`RX_MAC_ENTITY_NUM][int unsigned];
   bit [7:0] seg_pld_q[`RX_MAC_ENTITY_NUM][int unsigned][$];
   bit [31:0] seg_pld_addr[`RX_MAC_ENTITY_NUM][int unsigned];
   bit [31:0] seg_pld_8cp_addr[`RX_MAC_ENTITY_NUM][int unsigned];
   bit [7:0] asmb_seg_pdcp_dc[`RX_MAC_ENTITY_NUM][int unsigned]; 

   rand nr_l2dl_mce_cfg         mce_cfg[31];

   bit  [7:0] l1_mce_node_byte_q[$];
   bit  [7:0] l2_mce_node_byte_q[$];
   bit  [7:0] dl_node0_byte_q[$];
   bit  [7:0] acc_node_byte_q[$];
   int        mce_pld_length;
   int        l1_mce_num;
   int        l2_mce_num;
   int        l2_node0_num;
   int        l2_acc_num,tb_acc_num;
   bit [17:0] acc_pdcp_sn; 
   bit [17:0] acc_rlc_sn; 

   
   //function and task
   extern function new(string name="nr_l2dl_init_seq");
   extern virtual task body();
   extern virtual task reset_signal_proc();
   extern virtual task write_ddr_bytes(input bit [31:0] addr, ref bit [7:0] byte_steam[]);
   extern virtual task read_ddr_bytes(input bit [31:0] addr, ref bit [7:0] byte_steam[]);
   extern virtual task set_lc_cfg();
   extern virtual task set_l2glb_cfg();
   extern virtual task set_nr_l2_reg_cfg(input bit [6:0] tb_idx, ref NrL2RegConfig L2RegConfig);
   extern virtual task id_gen();
   extern virtual task cfg_gen();
   extern virtual task start_addr_vmem_cfg(int data_len, output bit [31:0] data_addr);
   extern virtual task write_node(ref bit [7:0] l1_mce_node_byte_q[$], ref bit [7:0] l2_mce_node_byte_q[$], ref bit [7:0] dl_node0_byte_q[$], ref bit [7:0] acc_node_byte_q[$]);
   extern virtual task tb_info_gen(input bit [6:0] tb_idx);
   extern virtual task random_sn_seg_na_discard_proc(input[5:0] lc_id, input [17:0] sn, input int unsigned seg_number, input int unsigned pdu_reassembly_length);
   extern virtual task sample_reg_cfg();


endclass: nr_l2dl_init_seq

function nr_l2dl_init_seq::new(string name="nr_l2dl_init_seq");
   super.new(name);
   mac_pkt   = nr_l2dl_mac_pkt::type_id::create("mac_pkt");
   rlc_pkt   = nr_l2dl_rlc_pkt::type_id::create("rlc_pkt");
   pdcp_pkt  = nr_l2dl_pdcp_pkt::type_id::create("pdcp_pkt");
   sdap_pkt  = nr_l2dl_sdap_pkt::type_id::create("sdap_pkt");
   pload_pkt = nr_l2dl_pld_pkt::type_id::create("pload_pkt");
   exp_dl_node0 = rx_mac_dl_node0::type_id::create("exp_dl_node0");
endfunction : new

task nr_l2dl_init_seq::body();
      uvm_status_e     status;
      uvm_reg_data_t   data;
      bit [7:0]        bytes[] = new[16];
      `uvm_info(get_name(), "nr_l2dl_init_seq begin...", UVM_NONE);
      get_config();
      reset_signal_proc(); 
      set_model(m_l2_reg_model);
      set_lc_cfg();
      set_l2glb_cfg();
      `uvm_info(get_name(), "c-model config  begin...", UVM_DEBUG);
      id_gen();
      cfg_gen();
      foreach(mce_cfg[ii]) begin
          m_nr_l2dl_env_cfg.mce_cfg[ii] = mce_cfg[ii];
      end
      if(`TB_NUM == 1)begin
          set_nr_l2_reg_cfg(m_nr_l2dl_env_cfg.tb_index,m_nr_l2_reg_cfg);
          write_node(l1_mce_node_byte_q,l2_mce_node_byte_q,dl_node0_byte_q,acc_node_byte_q);
          tb_info_gen(m_nr_l2dl_env_cfg.tb_index -`TB_IDX);
          `uvm_info(get_name(), "c-model main  begin...", UVM_DEBUG);
          main_rx_mac(m_nr_l2_reg_cfg);
      end else begin
          for(int ii=`TB_IDX; ii<`TB_NUM+`TB_IDX; ii++)begin
              set_nr_l2_reg_cfg(ii,m_nr_l2_reg_cfg);
              write_node(l1_mce_node_byte_q,l2_mce_node_byte_q,dl_node0_byte_q,acc_node_byte_q);
              tb_info_gen(ii-`TB_IDX);
              `uvm_info(get_name(), "c-model main  begin...", UVM_DEBUG);
              main_rx_mac(m_nr_l2_reg_cfg);
          end
      end
      sample_reg_cfg();
      `uvm_info(get_name(), "nr_l2dl_init_seq end...", UVM_NONE)
      
endtask : body

task nr_l2dl_init_seq::reset_signal_proc();
endtask : reset_signal_proc

task nr_l2dl_init_seq::sample_reg_cfg();
    m_nr_l2dl_coverage.sample_reg_cfg(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg);
endtask : sample_reg_cfg

task nr_l2dl_init_seq::read_ddr_bytes(input bit [31:0] addr, ref bit [7:0] byte_steam[]);
    read_vmem_bytes(m_nr_l2dl_env_cfg.ddr_mem, addr, byte_steam, m_nr_l2dl_env_cfg.ddr_mem_map, UVM_BACKDOOR);
endtask : read_ddr_bytes

task nr_l2dl_init_seq::write_ddr_bytes(input bit [31:0] addr, ref bit [7:0] byte_steam[]);
    write_vmem_bytes(m_nr_l2dl_env_cfg.ddr_mem, addr, byte_steam, m_nr_l2dl_env_cfg.ddr_mem_map, UVM_BACKDOOR);
    write_vmem_bytes(m_nr_l2dl_env_cfg.m_rx_mac_env_cfg.ddr_mem, addr, byte_steam, m_nr_l2dl_env_cfg.m_rx_mac_env_cfg.ddr_mem_map, UVM_BACKDOOR);
endtask : write_ddr_bytes

task nr_l2dl_init_seq::set_lc_cfg();
    int unsigned intstream[];
    foreach(m_nr_l2dl_env_cfg.lc_cfg[ii]) begin
        void'(m_nr_l2dl_env_cfg.lc_cfg[ii].pack_ints(intstream, default_packer));
        write_reg_by_name($sformatf("l2_lgch_rf.logic_ch_reg0_c%0d_logic_ch_reg1_c%0d", ii, ii), {intstream[1],intstream[0]});
        write_reg_by_name($sformatf("l2_lgch_rf.rx_deliv_reg_c%0d", ii), m_nr_l2dl_env_cfg.rx_deliv[ii]);
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("lc_cfg[%0d] is \n%s", ii, m_nr_l2dl_env_cfg.lc_cfg[ii].sprint()), UVM_MEDIUM)
    end
    for(int ii=0; ii<4; ii++)begin
        write_reg_by_name($sformatf("l2_lgch_rf.key_enc_reg_0_c%0d_key_enc_reg_1_c%0d", ii, ii), m_nr_l2dl_env_cfg.key_enc[ii][63:0]);
        write_reg_by_name($sformatf("l2_lgch_rf.key_enc_reg_2_c%0d_key_enc_reg_3_c%0d", ii, ii), m_nr_l2dl_env_cfg.key_enc[ii][127:64]);
        write_reg_by_name($sformatf("l2_lgch_rf.key_int_reg_0_c%0d_key_int_reg_1_c%0d", ii, ii), m_nr_l2dl_env_cfg.key_int[ii][63:0]);
        write_reg_by_name($sformatf("l2_lgch_rf.key_int_reg_2_c%0d_key_int_reg_3_c%0d", ii, ii), m_nr_l2dl_env_cfg.key_int[ii][127:64]);
    end
endtask : set_lc_cfg

task nr_l2dl_init_seq::set_l2glb_cfg();
    write_reg_by_name("globle_cfg_reg0_globle_cfg_reg1", {15'h0,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.tb_dbgout_en,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len,28'h0,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dtc_aucg_en,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.bit_inv_en,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.byte_inv_en,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.rxmac_work_en});
    write_reg_by_name("globle_cfg_reg4_globle_cfg_reg5", {15'h0,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_en,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_bits,24'h0,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.seg_buf_size,m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.asmb_seg_type});
    write_field_by_name("blk_size", "dma_cfg_reg8_dma_blkaddr_fifo_reg_0", m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.blk_size);
    write_field_by_name("l2glb_cfg_done", "logic_ch_cfg_done_reg", m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.lgch_cfg_done);
endtask : set_l2glb_cfg

task nr_l2dl_init_seq::set_nr_l2_reg_cfg(input bit [6:0] tb_idx, ref NrL2RegConfig L2RegConfig);
    int  mce_num, normal_node_num, err_num, padding_num;
    int  idx;
    int  dbg_idx=0;
    bit   [63:0]   byte_8;
    bit   [63:0]   cp_hdr;
    bit   [ 7:0]   normal_hdr_q[][$],normal_pld_q[][$],mce_byte_q[][$],padding_byte_q[$];
    bit   [ 3:0]   mac_hdr_l='h0;
    bit   [ 3:0]   rlc_hdr_l='h0;
    bit   [ 3:0]   pdcp_hdr_l='h0;
    bit   [ 3:0]   sdap_hdr_l='h0;
    bit   [23:0]   pload_s;
    bit   [ 7:0]   encoder_hdr;

    bit   [ 7:0]   node_data[];
    bit   [ 7:0]   pload_data[];
    bit   [31:0]   pload_addr;

    int  continuous_data_num;
    int unsigned l_max_value;
    int unsigned reassembly_length;

    mce_num = m_nr_l2dl_env_cfg.mce_num;
    normal_node_num = m_nr_l2dl_env_cfg.normal_node_num;
    err_num = m_nr_l2dl_env_cfg.err_num;
    padding_num = m_nr_l2dl_env_cfg.padding_num;

    L2RegConfig.fileindex = tb_idx;
    L2RegConfig.SegmentType = m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.asmb_seg_type;
    L2RegConfig.LogicChannelNum = `RX_MAC_ENTITY_NUM;
    L2RegConfig.DtcNodeNum = mce_num + normal_node_num + padding_num;//
    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb_idx=%0d, SegmentType=%0d, LogicChannelNum=%0d, DtcNodeNum=%0d m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg is \n%s", L2RegConfig.fileindex, L2RegConfig.SegmentType, L2RegConfig.LogicChannelNum, L2RegConfig.DtcNodeNum, m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.sprint()), UVM_MEDIUM)

    normal_hdr_q = new[normal_node_num];
    normal_pld_q = new[normal_node_num];
    mce_byte_q = new[mce_num];

    l_max_value =160512-14*normal_node_num-11*padding_num;//TODO: need to redefined
    for(int ii=0; ii<mce_num; ii++) begin
        mce_node = rx_mac_mce_node::type_id::create("mce_node");
            
        l_max_value = l_max_value-mce_byte_q[ii].size();//TODO: need to redefined

        assert(mac_pkt.randomize() with {
           mc_type inside {mac_ce_base, mac_ce_l8};
           if(mc_type == mac_ce_base){
              lcid inside {mce_fixed_lcid_q}; 
              l==0;
           }
           if(mc_type inside {mac_ce_l8}){
              lcid inside {mce_nonfixed_lcid_q};
              l <= 255-3;
              l >0;
           }
        });
        mac_pkt.pack_hdr(0, mce_byte_q[ii], mac_hdr_l);
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_mce_pkt[%0d] mac_hdr_l=%0d, mac_pkt is \n%s", tb_idx, ii, mac_hdr_l, mac_pkt.sprint()), UVM_MEDIUM)
        assert(pload_pkt.randomize());

        if(mac_pkt.mc_type == nr_l2dl_mac_pkt::mac_ce_base) begin
            pload_s = m_nr_l2dl_env_cfg.mce_cfg[(mac_pkt.lcid) - 33].length;
        end
        else begin
            pload_s = mac_pkt.l;
        end
        pload_pkt.pack_hdr(pload_s, mce_byte_q[ii]);
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_mce_pkt[%0d] pload_s=%0d, mac_pkt.l=%0d", tb_idx, ii, pload_s, mac_pkt.l), UVM_MEDIUM)
        m_nr_l2dl_env_cfg.tb_size[tb_idx] = m_nr_l2dl_env_cfg.tb_size[tb_idx] + mac_hdr_l + pload_s;  
        
        L2RegConfig.DTCNode[ii].continuousDataNum = 1; //=1
        L2RegConfig.DTCNode[ii].RbDirInfo = 'h0;
        L2RegConfig.DTCNode[ii].controlbits = 'hb00;// (destination<<11)|(encoderheader<<6|lcid);
        L2RegConfig.DTCNode[ii].StartCount = 'h0;
        L2RegConfig.DTCNode[ii].sdapheader = 1;
        L2RegConfig.DTCNode[ii].offset = 0;
        L2RegConfig.DTCNode[ii].StartRlcSn = 'h0;
        L2RegConfig.DTCNode[ii].rlcpdcpbits = 'h0;//(SI&0x03)|(POLL<<2);
        L2RegConfig.DTCNode[ii].SoStart =0;
        L2RegConfig.DTCNode[ii].SegmentLength =0;
        L2RegConfig.DTCNode[ii].next = (ii == mce_num - 1) ? 0 : ii+1;
        for(int jj=ii; jj<ii+1; jj++) begin
            foreach(mce_byte_q[ii][kk]) begin
                if(kk%8 == 0)       byte_8[7:0] = mce_byte_q[ii][kk];       
                else if(kk%8 == 1)  byte_8[15:8] = mce_byte_q[ii][kk];
                else if(kk%8 == 2)  byte_8[23:16] = mce_byte_q[ii][kk];
                else if(kk%8 == 3)  byte_8[31:24] = mce_byte_q[ii][kk];
                else if(kk%8 == 4)  byte_8[39:32] = mce_byte_q[ii][kk];
                else if(kk%8 == 5)  byte_8[47:40] = mce_byte_q[ii][kk];
                else if(kk%8 == 6)  byte_8[55:48] = mce_byte_q[ii][kk];
                else if(kk%8 == 7)  byte_8[63:56] = mce_byte_q[ii][kk];
                if((kk%8 == 7) || (kk == mce_byte_q[ii].size() - 1)) begin
                    idx = $ceil(kk/8);
                    L2RegConfig.DataInfo[jj].dataAddr[idx] = byte_8;//
                    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_mce_pkt[%0d] mce_byte_q[%0d].size()=%0d, mce_byte_8[%0d]=%0h", tb_idx, ii, ii, mce_byte_q[ii].size(), ii, byte_8), UVM_DEBUG)
                    byte_8 = 'h0;
                end
            end
            L2RegConfig.DataInfo[jj].dataLen = mce_byte_q[ii].size();//payloade1 length max 1500byte
        end
        L2RegConfig.DTCNode[ii].firstptr = ii;
        //save mace pload
        if(pload_s>0)begin
            start_addr_vmem_cfg(pload_s,pload_addr);//pload_addr

            pload_data = new[pload_s];
            foreach(pload_data[jj]) begin
                pload_data[jj] = mce_byte_q[ii][jj+mac_hdr_l]; 
            end
            write_ddr_bytes(pload_addr, pload_data);
            pload_data.delete();
        end

        //mce node 
        assert(mce_node.randomize() with {
             lcid== mac_pkt.lcid;
             l== mac_pkt.l;
             mce_start_addr == pload_addr; 
             //mce_start_addr == (mce_pld_length + pload_s > m_nr_l2dl_env_cfg.macce_pld_space)? m_nr_l2dl_env_cfg.macce_pld_addr : m_nr_l2dl_env_cfg.macce_pld_addr + mce_pld_length;
        });
        void'(mce_node.pack_bytes(node_data, default_packer));
        if(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.macce_dec_bits[mac_pkt.lcid-47]==1'b0) begin
        //l1
            foreach(node_data[ii]) begin
                l1_mce_node_byte_q.push_back(node_data[ii]);
            end
        end
        else begin
        //l2
            foreach(node_data[ii]) begin
                l2_mce_node_byte_q.push_back(node_data[ii]);
            end
        end
        mce_pld_length= mce_pld_length + pload_s;
        //colletc mce node coverage
        m_nr_l2dl_coverage.sample_mce_node(mce_node);
    end

    foreach(m_nr_l2dl_env_cfg.lc_cfg[ii]) begin
        //foreach(seg_pkt_pool[ii][jj])begin
        //    seg_pkt_pool[ii][jj].delete();
        //end
        L2RegConfig.Lcid[ii] = ii;
        L2RegConfig.nrLogicalChannelConfigTable[ii].LCID = ii;
        L2RegConfig.nrLogicalChannelConfigTable[ii].RBid  = m_nr_l2dl_env_cfg.lc_cfg[ii].rb_id;
        L2RegConfig.nrLogicalChannelConfigTable[ii].isSrb = m_nr_l2dl_env_cfg.lc_cfg[ii].rb_type;
        L2RegConfig.nrLogicalChannelConfigTable[ii].UlrlcMode = m_nr_l2dl_env_cfg.lc_cfg[ii].rlc_mode;
        L2RegConfig.nrLogicalChannelConfigTable[ii].UlrlcSnLength = m_nr_l2dl_env_cfg.lc_cfg[ii].rlc_sn_len;
        L2RegConfig.nrLogicalChannelConfigTable[ii].UlPdcpSnLength = m_nr_l2dl_env_cfg.lc_cfg[ii].pdcp_sn_len;
        L2RegConfig.nrLogicalChannelConfigTable[ii].UlSdapheaderPresent = m_nr_l2dl_env_cfg.lc_cfg[ii].sdap_hdr_present;
        L2RegConfig.nrLogicalChannelConfigTable[ii].isUlActive = m_nr_l2dl_env_cfg.lc_cfg[ii].lgch_active;
        L2RegConfig.nrLogicalChannelConfigTable[ii].DlrlcMode = m_nr_l2dl_env_cfg.lc_cfg[ii].rlc_mode;
        L2RegConfig.nrLogicalChannelConfigTable[ii].DlrlcSnLength = m_nr_l2dl_env_cfg.lc_cfg[ii].rlc_sn_len;
        L2RegConfig.nrLogicalChannelConfigTable[ii].DlPdcpSnLength = m_nr_l2dl_env_cfg.lc_cfg[ii].pdcp_sn_len;
        L2RegConfig.nrLogicalChannelConfigTable[ii].DlSdapheaderPresent = m_nr_l2dl_env_cfg.lc_cfg[ii].sdap_hdr_present;
        L2RegConfig.nrLogicalChannelConfigTable[ii].isDlActive = m_nr_l2dl_env_cfg.lc_cfg[ii].lgch_active;
        L2RegConfig.nrLogicalChannelConfigTable[ii].Softdecipherandintegrity = m_nr_l2dl_env_cfg.lc_cfg[ii].sft_dtc;
        L2RegConfig.nrLogicalChannelConfigTable[ii].L2headerIntervalPresent = 0;
        L2RegConfig.nrLogicalChannelConfigTable[ii].PdcpSduIntervalSizeReserved = m_nr_l2dl_env_cfg.lc_cfg[ii].resvd_intv_size;
        L2RegConfig.nrLogicalChannelConfigTable[ii].DlPdcpWindowSize = m_nr_l2dl_env_cfg.lc_cfg[ii].pdcp_window_size;
        L2RegConfig.nrLogicalChannelConfigTable[ii].cipAlgo = m_nr_l2dl_env_cfg.lc_cfg[ii].dtc_decip_algo;
        L2RegConfig.nrLogicalChannelConfigTable[ii].cipherPresent = m_nr_l2dl_env_cfg.lc_cfg[ii].cip_present;
        L2RegConfig.nrLogicalChannelConfigTable[ii].intAlgo = m_nr_l2dl_env_cfg.lc_cfg[ii].dtc_deint_algo;
        L2RegConfig.nrLogicalChannelConfigTable[ii].integrityPresent = m_nr_l2dl_env_cfg.lc_cfg[ii].int_present;
        L2RegConfig.nrLogicalChannelConfigTable[ii].KeyEnc[0] = m_nr_l2dl_env_cfg.key_enc[ii][63:0];
        L2RegConfig.nrLogicalChannelConfigTable[ii].KeyInt[0] = m_nr_l2dl_env_cfg.key_int[ii][63:0];
        L2RegConfig.nrLogicalChannelConfigTable[ii].KeyEnc[1] = m_nr_l2dl_env_cfg.key_enc[ii][127:64];
        L2RegConfig.nrLogicalChannelConfigTable[ii].KeyInt[1] = m_nr_l2dl_env_cfg.key_int[ii][127:64];
        L2RegConfig.RX_DELIV[ii] = m_nr_l2dl_env_cfg.rx_deliv[ii]; 
        `uvm_info(get_name(), $sformatf("rb_id[%0d]=%0h, resvd_intv_size[%0d]=%0h, normal_node_num=%0d", L2RegConfig.Lcid[ii], m_nr_l2dl_env_cfg.lc_cfg[ii].rb_id, L2RegConfig.Lcid[ii], m_nr_l2dl_env_cfg.lc_cfg[ii].resvd_intv_size, normal_node_num), UVM_DEBUG)
    end

    begin
        for(int jj=mce_num; jj<normal_node_num+mce_num; jj++) begin
            rx_mac_seg_pkt_info seg_pkt;
            seg_pkt = rx_mac_seg_pkt_info::type_id::create("seg_pkt"); 
            dl_node0 = rx_mac_dl_node0::type_id::create("dl_node0");
            acc_node = rx_mac_acc_node::type_id::create("acc_node");
            
            l_max_value = l_max_value - normal_pld_q[jj-mce_num].size();//TODO: need to redefined
            //dl_node0
            assert(dl_node0.randomize() with {
                 l inside {[14:1514]};
                 lcid == m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].lcid;
                 polling== m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].polling;
                 rlc_sn== m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].rlc_sn;
                 pdcp_sn == m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn;
                 qfi == 'h0;
                 rqi == 'h0;
                 rdi == 'h0;
                 assemble_success == 'h0;
                 chk_err=='h0; //TODO:
                 if((m_nr_l2dl_env_cfg.lc_cfg[lcid].rb_type == nr_l2dl_lc_cfg::SRB) || (m_nr_l2dl_env_cfg.lc_cfg[lcid].cip_present == nr_l2dl_lc_cfg::CIP_PRESENT) || (m_nr_l2dl_env_cfg.lc_cfg[lcid].int_present == nr_l2dl_lc_cfg::INTEGRITY_PRESENT)){
                     pdcp_dc == 'h1;
                 }
            });
            //collect lc_cfg coverage
            m_nr_l2dl_coverage.sample_lc_cfg(m_nr_l2dl_env_cfg.lc_cfg[m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].lcid]);

            if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::SDAP_DATA)begin
                if(dl_node0.l>=l_max_value)begin
                    dl_node0.l = $urandom_range(14,14+l_max_value);
                end
                dl_node0.dec_pdcp_hdr = 'h1;
                dl_node0.decipher_pdcp_data = (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sft_dtc == nr_l2dl_lc_cfg::SFT_DTC) && (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cip_present == nr_l2dl_lc_cfg::CIP_PRESENT);
                dl_node0.rlc_dc = 'h1;
                dl_node0.pdcp_dc = 'h1;
                dl_node0.si = 'h0;
                dl_node0.so = 'h0;
                if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present == nr_l2dl_lc_cfg::NO_HDR)begin
                    dl_node0.qfi = 'h0;
                    dl_node0.rqi = 'h0;
                    dl_node0.rdi = 'h0;
                end
                if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_AM)begin
                    if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_type == nr_l2dl_lc_cfg::SRB)begin
                        dl_node0.data_byte_len=(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1) ?
                            (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12 ? 
                                dl_node0.l-2-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8 : 
                                dl_node0.l-3-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8) :
                            (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12 ? 
                                dl_node0.l-2-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present : 
                                dl_node0.l-3-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present);
                    end 
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_type == nr_l2dl_lc_cfg::DRB)begin
                        dl_node0.data_byte_len=(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1) ? 
                            (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12 ? 
                                (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12 ?                  
                                    dl_node0.l-2-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8 : 
                                    dl_node0.l-2-3-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8) : 
                                (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12 ?                  
                                    dl_node0.l-3-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8 : 
                                    dl_node0.l-3-3-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8)) : 
                            (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12 ? 
                                (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12 ?                  
                                    dl_node0.l-2-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present : 
                                    dl_node0.l-2-3-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present) : 
                                (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12 ?                  
                                    dl_node0.l-3-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present : 
                                    dl_node0.l-3-3-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present)); 
                    end 
                end 
                else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_UM)begin
                    if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_type == nr_l2dl_lc_cfg::SRB)begin
                        dl_node0.data_byte_len=(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1) ? 
                            dl_node0.l-1-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8 :
                            dl_node0.l-1-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present; 
                    end 
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_type == nr_l2dl_lc_cfg::DRB)begin
                        dl_node0.data_byte_len=(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1) ? 
                            (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12 ?                  
                             dl_node0.l-1-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8 : 
                             dl_node0.l-1-3-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present+8) : 
                            (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12 ?                  
                             dl_node0.l-1-2-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present : 
                             dl_node0.l-1-3-m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present-4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present); 
                    end 
                end 
            end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_CTRL)begin
                if(dl_node0.l>=l_max_value)begin
                    dl_node0.l = $urandom_range(10,10+l_max_value);
                end
                dl_node0.data_byte_len=dl_node0.l;
                dl_node0.dec_pdcp_hdr='h0;
                dl_node0.decipher_pdcp_data='h0;
                dl_node0.pdcp_sn = 'h0;
                dl_node0.rlc_dc='h0;
                dl_node0.pdcp_dc='h1;
                dl_node0.si = 'h0;
                dl_node0.so = 'h0;
                dl_node0.qfi = 'h0;
                dl_node0.rqi = 'h0;
                dl_node0.rdi = 'h0;
            end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG)begin
                reassembly_length = $urandom_range(10,1500); 
                if(reassembly_length>=l_max_value)begin
                    reassembly_length = $urandom_range(10,l_max_value);
                end
                if(seg_pkt_pool[dl_node0.lcid][dl_node0.rlc_sn].size() == 0)begin
                    random_sn_seg_na_discard_proc(dl_node0.lcid,dl_node0.rlc_sn,m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].seg_num,reassembly_length);
                    //dl_node0_length[dl_node0.lcid][dl_node0.rlc_sn] = 0;
                    dl_node0_length[dl_node0.lcid][dl_node0.rlc_sn] = reassembly_length;
                    asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn][0] = dl_node0.pdcp_dc[0]; 
                    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("lcid[%0d]_sn[%0d] seg_num=%0d, reassembly_length=%0d seg_pkt_size=%0d", dl_node0.lcid,dl_node0.rlc_sn,m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].seg_num,reassembly_length,seg_pkt_pool[dl_node0.lcid][dl_node0.rlc_sn].size()), UVM_MEDIUM)            
                end
                if(seg_pkt_pool[dl_node0.lcid][dl_node0.rlc_sn].size() == 1) begin
                    dl_node0.assemble_success = m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.asmb_seg_type;
                end
                seg_pkt = seg_pkt_pool[dl_node0.lcid][dl_node0.rlc_sn].pop_front();
                `uvm_info($sformatf("%25s", get_full_name()), $sformatf("lcid[%0d]_sn[%0d] seg_pkt is \n%s", dl_node0.lcid, dl_node0.rlc_sn, seg_pkt.sprint()), UVM_MEDIUM)            
                dl_node0.si = seg_pkt.rlc_si;
                dl_node0.so = seg_pkt.rlc_so;
                //dl_node0_length[dl_node0.lcid][dl_node0.rlc_sn] = dl_node0_length[dl_node0.lcid][dl_node0.rlc_sn] + seg_pkt.rlc_pdu_length; 
                dl_node0.pdcp_sn = (dl_node0.assemble_success == 'h1 && asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn]) ? dl_node0.pdcp_sn : 'h0;
                dl_node0.data_byte_len = seg_pkt.rlc_pdu_length;
                dl_node0.dec_pdcp_hdr = ((dl_node0.assemble_success == 'h1) && (asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn]=='h1)) ? 'h1 : 'h0;
                dl_node0.decipher_pdcp_data = ((dl_node0.assemble_success == 'h1) && (asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn]=='h1)) ? (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sft_dtc == nr_l2dl_lc_cfg::SFT_DTC) && (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cip_present == nr_l2dl_lc_cfg::CIP_PRESENT) : 'h0;
                dl_node0.pdcp_dc = (dl_node0.assemble_success == 'h1) ? asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn] : 'h1;
                dl_node0.rlc_dc ='h1;
                dl_node0.qfi = 'h0;
                dl_node0.rqi = 'h0;
                dl_node0.rdi = 'h0;
                if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_AM)begin
                    if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12)begin
                        if(dl_node0.si[1]=='b0)begin
                            dl_node0.l= dl_node0.data_byte_len+2;
                        end else begin
                            dl_node0.l= dl_node0.data_byte_len+4;
                        end 
                    end 
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_18)begin
                        if(dl_node0.si[1]=='b0)begin
                            dl_node0.l= dl_node0.data_byte_len+3;
                        end else begin
                            dl_node0.l= dl_node0.data_byte_len+5;
                        end 
                    end 
                end 
                else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_UM)begin
                    if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_6)begin
                         if(dl_node0.si[1]=='b0)begin
                             dl_node0.l= dl_node0.data_byte_len+1;
                         end else begin
                             dl_node0.l= dl_node0.data_byte_len+3;
                         end 
                    end 
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12)begin
                         if(dl_node0.si[1]=='b0)begin
                             dl_node0.l= dl_node0.data_byte_len+2;
                         end else begin
                             dl_node0.l= dl_node0.data_byte_len+4;
                         end 
                    end 
                end
                dl_node0.data_byte_len = dl_node0.assemble_success == 'h1 ? 
                                             (dl_node0.pdcp_dc=='h0 ? dl_node0_length[dl_node0.lcid][dl_node0.rlc_sn] :
                                              ((m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_type == nr_l2dl_lc_cfg::DRB)&&(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_18) ? 
                                                  dl_node0_length[dl_node0.lcid][dl_node0.rlc_sn] - 'h3 - m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present - 4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present + 8*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en:
                                                  dl_node0_length[dl_node0.lcid][dl_node0.rlc_sn] - 'h2 - m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present - 4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present + 8*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en)) : 
                                             seg_pkt.rlc_pdu_length;

            end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_TMD)begin
                if(dl_node0.l>=l_max_value)begin
                    dl_node0.l = $urandom_range(10,10+l_max_value);
                end
                dl_node0.data_byte_len = dl_node0.l;
                dl_node0.dec_pdcp_hdr='h0;
                dl_node0.decipher_pdcp_data='h0;
                dl_node0.pdcp_sn = 'h0;
                dl_node0.rlc_dc='h1;
                dl_node0.pdcp_dc='h1;
                dl_node0.si = 'h0;
                dl_node0.so = 'h0;
                dl_node0.qfi = 'h0;
                dl_node0.rqi = 'h0;
                dl_node0.rdi = 'h0;
            end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::PDCP_CTRL)begin
                if(dl_node0.l>=l_max_value)begin
                    dl_node0.l = $urandom_range(10,10+l_max_value);
                end
                dl_node0.dec_pdcp_hdr = 'h0;
                dl_node0.decipher_pdcp_data ='h0;
                dl_node0.rlc_dc = 'h1;
                dl_node0.pdcp_sn = 'h0;
                dl_node0.pdcp_dc = 'h0;
                dl_node0.si = 'h0;
                dl_node0.so = 'h0;
                dl_node0.qfi = 'h0;
                dl_node0.rqi = 'h0;
                dl_node0.rdi = 'h0;
                if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_AM)begin
                    dl_node0.data_byte_len=(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12) ? dl_node0.l-2 : dl_node0.l-3;
                end 
                else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_UM)begin
                    dl_node0.data_byte_len=dl_node0.l-1;
                end
            end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::ERR)begin
                if(dl_node0.l>=l_max_value)begin
                    dl_node0.l = $urandom_range(10,10+l_max_value);
                end
            end 
            if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG) && (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].seg_num == seg_pkt_pool[dl_node0.lcid][dl_node0.rlc_sn].size()+'h1)) begin
                if((m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.asmb_seg_type == 'h1) && (asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn] == 'h1) && (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1))begin
                    start_addr_vmem_cfg(reassembly_length,seg_pld_addr[dl_node0.lcid][dl_node0.rlc_sn]);//pload_addr
                    start_addr_vmem_cfg(reassembly_length+8,seg_pld_8cp_addr[dl_node0.lcid][dl_node0.rlc_sn]);//pload_addr
                end else begin
                    start_addr_vmem_cfg(reassembly_length,seg_pld_addr[dl_node0.lcid][dl_node0.rlc_sn]);//pload_addr
                end
            end
            //acc_node
            assert(acc_node.randomize() with{
                lcid==dl_node0.lcid;
                if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::SDAP_DATA){
                    sdu_type[4:0]==5'h1;//0:normal_padcp(si=0); 1:rlc_seg(si!=0);2:rlc_ctrl;3:pdcp_ctrl;4:tm_sdu;5:padding;6:protocal_err;8:polling;9:rqi_or_rdi;11~15:error_type
                    sdu_type[15:11]==5'h0;
                } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG){
                    sdu_type[4:0]==5'h2;
                    sdu_type[15:11]==5'h0;
                } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_CTRL){
                    sdu_type[4:0]==5'h4;
                    sdu_type[15:11]==5'h0;
                } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::PDCP_CTRL){
                    sdu_type[4:0]==5'h8;
                    sdu_type[15:11]==5'h0;
                } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_TMD){
                    sdu_type[4:0]==5'h10;
                    sdu_type[15:11]==5'h0;
                } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::ERR){
                    sdu_type[4:0]==5'h0;
                    sdu_type[15:11]==5'h0;
                }
                sdu_type[5]==1'b0;//padding
                sdu_type[6]==dl_node0.chk_err;//protocal_err
                sdu_type[7]==1'b0;
                if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG) && (dl_node0.assemble_success == 'h1)){
                    sdu_type[8]== 'h0;//polling
                }else{
                    sdu_type[8]== dl_node0.polling;//polling
                }
                if((dl_node0.rqi==1'b1) || (dl_node0.rdi ==1'b1)){
                    sdu_type[9]==1'b1;
                } else{
                    sdu_type[9]==1'b0;
                }
                sdu_type[10]==1'b0;
            });
            if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::SDAP_DATA)&&(dl_node0.pdcp_sn == acc_pdcp_sn + 1)&&(acc_node_tr_q[0].lcid == dl_node0.lcid)&&(acc_node_tr_q[0].sdu_type == acc_node.sdu_type)&&((m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_UM) || ((m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_AM)&&(dl_node0.rlc_sn == acc_rlc_sn + 1))))begin
                acc_node=acc_node_tr_q.pop_back;
                acc_node.total_sdu_len = acc_node.total_sdu_len + dl_node0.l; 
                acc_node.l2_node_num = acc_node.l2_node_num + 1; 
                acc_node_tr_q.push_back(acc_node);
            end else begin
                if(acc_node_tr_q.size()>0)begin
                    acc_node=acc_node_tr_q.pop_front;
                    tb_acc_num++;
                    void'(acc_node.pack_bytes(node_data, default_packer));
                    foreach(node_data[ii]) begin
                        acc_node_byte_q.push_back(node_data[ii]);
                    end
                    node_data.delete();
                end
                assert(acc_node.randomize() with{
                    lcid==dl_node0.lcid;
                    if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::SDAP_DATA){
                        sdu_type[4:0]==5'h1;//0:normal_padcp(si=0); 1:rlc_seg(si!=0);2:rlc_ctrl;3:pdcp_ctrl;4:tm_sdu;5:padding;6:protocal_err;8:polling;9:rqi_or_rdi;11~15:error_type
                        sdu_type[15:11]==5'h0;
                    } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG){
                        sdu_type[4:0]==5'h2;
                        sdu_type[15:11]==5'h0;
                    } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_CTRL){
                        sdu_type[4:0]==5'h4;
                        sdu_type[15:11]==5'h0;
                    } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::PDCP_CTRL){
                        sdu_type[4:0]==5'h8;
                        sdu_type[15:11]==5'h0;
                    } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_TMD){
                        sdu_type[4:0]==5'h10;
                        sdu_type[15:11]==5'h0;
                    } else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::ERR){
                        sdu_type[4:0]==5'h0;
                        sdu_type[15:11]==5'h0;
                    }
                    sdu_type[5]==1'b0;//padding
                    sdu_type[6]==dl_node0.chk_err;//protocal_err
                    sdu_type[7]==1'b0;
                    if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG) && (dl_node0.assemble_success == 'h1)){
                        sdu_type[8]== 'h0;//polling
                    }else{
                        sdu_type[8]== dl_node0.polling;//polling
                    }
                    if((dl_node0.rqi==1'b1) || (dl_node0.rdi ==1'b1)){
                        sdu_type[9]==1'b1;
                    } else{
                        sdu_type[9]==1'b0;
                    }
                    sdu_type[10]==1'b0;
                    total_sdu_len==dl_node0.l;
                    l2_node_num == 1; 
                    if((m_nr_l2dl_env_cfg.normal_node_num%32>0)&&(l2_node0_num>0)){
                        first_l2dl_node_idx == (32*(l2_node0_num/m_nr_l2dl_env_cfg.normal_node_num)+l2_node0_num+jj-mce_num-(m_nr_l2dl_env_cfg.normal_node_num%32)*(l2_node0_num/m_nr_l2dl_env_cfg.normal_node_num))%m_nr_l2dl_env_cfg.dl_node0_space;
                    }else{
                        first_l2dl_node_idx == (l2_node0_num+jj-mce_num)%m_nr_l2dl_env_cfg.dl_node0_space;
                    }
                    if((m_nr_l2dl_env_cfg.normal_node_num%32>0)&&(l2_node0_num>0)){
                        first_l2dl_ptr_idx == (32*(l2_node0_num/m_nr_l2dl_env_cfg.normal_node_num)+l2_node0_num+jj-mce_num-(m_nr_l2dl_env_cfg.normal_node_num%32)*(l2_node0_num/m_nr_l2dl_env_cfg.normal_node_num))%m_nr_l2dl_env_cfg.dl_node1_space;
                    }else{
                        first_l2dl_ptr_idx == (l2_node0_num+jj-mce_num)%m_nr_l2dl_env_cfg.dl_node1_space;
                    }
                });
                acc_node_tr_q.push_back(acc_node);
            end
            if((acc_node_tr_q.size()>0)&&(jj == normal_node_num+mce_num-1))begin
                acc_node=acc_node_tr_q.pop_front;
                tb_acc_num++;
                void'(acc_node.pack_bytes(node_data, default_packer));
                foreach(node_data[ii]) begin
                    acc_node_byte_q.push_back(node_data[ii]);
                end
                node_data.delete();
            end

            encoder_hdr = ((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_TMD) || (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_CTRL)) ? 'h0 : ((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG) || (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::PDCP_CTRL)) ? 'h3 : 'h2;   
            continuous_data_num = m_nr_l2dl_env_cfg.continuous_data_num;
            //continuous_data_num = ((rlc_pkt.d_c == 'h0) || (pdcp_pkt.d_c == 'h0) || (sdap_pkt.d_c == 'h0) || (rlc_pkt.si != 'h0)) ? 1 : m_nr_l2dl_env_cfg.continuous_data_num;

            L2RegConfig.DTCNode[jj].continuousDataNum = continuous_data_num;
            L2RegConfig.DTCNode[jj].RbDirInfo = m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_id;
            L2RegConfig.DTCNode[jj].sdapheader = {dl_node0.rdi,dl_node0.rqi,dl_node0.qfi};//rdi,rqi,qfi/d_c, r, qfi
            //L2RegConfig.DTCNode[jj].sdapheader = sdap_pkt.sdap_type_sel == nr_l2dl_sdap_pkt::sdap_normal ? {sdap_pkt.rdi,sdap_pkt.rqi,sdap_pkt.qfi} : {sdap_pkt.d_c, sdap_pkt.r, sdap_pkt.qfi};//rdi,rqi,qfi/d_c, r, qfi
            L2RegConfig.DTCNode[jj].offset = 0;
            L2RegConfig.DTCNode[jj].StartRlcSn = dl_node0.rlc_sn;
            L2RegConfig.DTCNode[jj].rlcpdcpbits = {dl_node0.polling[0], dl_node0.si[1:0]};//(SI&0x03)|(POLL<<2);
            L2RegConfig.DTCNode[jj].SoStart = dl_node0.so;
            L2RegConfig.DTCNode[jj].SegmentLength = m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG ? seg_pkt.rlc_pdu_length : 'h0;
            L2RegConfig.DTCNode[jj].next = (jj == normal_node_num+mce_num-1) ? 0 : jj+1;

            if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12)begin
                if((m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][11:0] >= m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_window_size)&&(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[11:0] < m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][11:0] - m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_window_size)) begin
                    L2RegConfig.DTCNode[jj].StartCount = {m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][31:12] + 1'h1,m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[11:0]};
                end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[11:0] >= m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][11:0] + m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_window_size)begin
                    L2RegConfig.DTCNode[jj].StartCount = {m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][31:12] - 1'h1,m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[11:0]};
                end else begin
                    L2RegConfig.DTCNode[jj].StartCount = {m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][31:12],m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[11:0]};
                end
            end else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_18)begin
                if((m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][17:0] >= m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_window_size)&&(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[17:0] < m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][17:0] - m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_window_size)) begin
                    L2RegConfig.DTCNode[jj].StartCount = {m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][31:18] + 1'h1,m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[17:0]};
                end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[17:0] >= {1'b0,m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][17:0]} + m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_window_size)begin
                    L2RegConfig.DTCNode[jj].StartCount = {m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][31:18] - 1'h1,m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[17:0]};
                end else begin
                    L2RegConfig.DTCNode[jj].StartCount = {m_nr_l2dl_env_cfg.rx_deliv[dl_node0.lcid][31:18],m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn[17:0]};
                end
            end
            if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_TMD) || (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::PDCP_CTRL) || (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_CTRL)) begin
                L2RegConfig.DTCNode[jj].controlbits = ('hb00)|(encoder_hdr<<6|dl_node0.lcid);// (destination<<11)|(encoderheader<<6|lcid);encoderheader=0,unadd_hdr;=2,mac+rlc+pdcp+sdap;=3,mac+rlc
            end else begin
                L2RegConfig.DTCNode[jj].controlbits = ('h800)|(encoder_hdr<<6|dl_node0.lcid);// (destination<<11)|(encoderheader<<6|lcid);encoderheader=0,unadd_hdr;=2,mac+rlc+pdcp+sdap;=3,mac+rlc
            end
            `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] dl_node0.data_byte_len=%0d, encoder_hdr=%0d, continuous_data_num=%0d", tb_idx, dl_node0.lcid, jj, dl_node0.data_byte_len, encoder_hdr, continuous_data_num), UVM_MEDIUM)            

            for(int kk=jj*continuous_data_num; kk<(jj+1)*continuous_data_num; kk++) begin
                assert(mac_pkt.randomize() with {
                    r == 'h0;
                    lcid == dl_node0.lcid;
                    if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_TMD) || 
                       (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::PDCP_CTRL) || 
                       (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_CTRL) || 
                       ((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG)&&(dl_node0.assemble_success == 'h0))){
                        l == dl_node0.l; 
                    }else{
                        l == dl_node0.l - 4*m_nr_l2dl_env_cfg.lc_cfg[lcid].int_present; 
                    }
                    if(l>255){ 
                        mc_type inside {mac_pdu_l16};
                    }else{
                        mc_type inside {mac_pdu_l8};
                    }
                });
                assert(rlc_pkt.randomize() with {
                    si == dl_node0.si;
                    so == dl_node0.so;
                    sn == dl_node0.rlc_sn; 
                    if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_AM){
                        if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12){
                            if(dl_node0.rlc_dc=='h0){
                                rlc_pdu_type inside {status_pdu}; 
                            }else if(si[1]==1'b0){
                                rlc_pdu_type inside {amd_pdu_base};
                            }else if(si[1]==1'b1){
                                rlc_pdu_type inside {amd_pdu_sn12_so16};
                            }
                        }
                        else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_18){
                            if(dl_node0.rlc_dc=='h0){
                                rlc_pdu_type inside {status_pdu}; 
                            }else if(si[1]==1'b0){
                                rlc_pdu_type inside {amd_pdu_sn18};
                            }else if(si[1]==1'b1){
                                rlc_pdu_type inside {amd_pdu_final};
                            }
                        }
                    }
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_UM){
                        if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_6){
                            if(si==2'b00){
                                rlc_pdu_type inside {umd_pdu_base};
                            }else if(si==2'b01){
                                rlc_pdu_type inside {umd_pdu_sn6};
                            }else if((si==2'b10)||(si==2'b11)){
                                rlc_pdu_type inside {umd_pdu_sn6_so16};
                            }
                        }
                        else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_sn_len == nr_l2dl_lc_cfg::RLC_SN_12){
                            if(si==2'b00){
                                rlc_pdu_type inside {umd_pdu_base};
                            }else if(si==2'b01){
                                rlc_pdu_type inside {umd_pdu_sn12};
                            }else if((si==2'b10)||(si==2'b11)){
                                rlc_pdu_type inside {umd_pdu_sn12_so16};
                            }
                        }
                    }
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode == nr_l2dl_lc_cfg::RLC_TM){
                        //rlc_pdu_type inside {status_pdu};
                    }
                });
                assert(pdcp_pkt.randomize() with {
                    pdcp_pkt.pdcp_sn == m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pdcp_sn;
                    if((dl_node0.pdcp_dc=='h0) || ((dl_node0.si != 'h0)&&(asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn] == 'h0))){
                        pdcp_type_sel inside {pdcp_ctl_pdu,pdcp_ctl_rohc};
                    }
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_type == nr_l2dl_lc_cfg::SRB){
                        pdcp_type_sel inside {pdcp_dat_pdu_srb};
                    }
                    else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_type == nr_l2dl_lc_cfg::DRB){
                        if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_12){
                            pdcp_type_sel inside {pdcp_dat_pdu_drb_12};
                        }
                        else if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].pdcp_sn_len == nr_l2dl_lc_cfg::PDCP_SN_18){
                            pdcp_type_sel inside {pdcp_dat_pdu_drb_18};
                        }
                    }
                });
                assert(sdap_pkt.randomize() with {
                    rdi == dl_node0.rdi;
                    rqi == dl_node0.rqi;
                    qfi == dl_node0.qfi;
                    sdap_type_sel inside {sdap_normal};
                });

                assert(pload_pkt.randomize());

                if((encoder_hdr == 'h2) || (encoder_hdr == 'h3))begin
                    mac_pkt.pack_hdr(0, normal_hdr_q[jj-mce_num], mac_hdr_l);
                    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] mac_hdr_l=%0d, mac_pkt is \n%s", tb_idx, dl_node0.lcid, jj, mac_hdr_l, mac_pkt.sprint()), UVM_MEDIUM)            
                    rlc_pkt.pack_hdr(normal_hdr_q[jj-mce_num], rlc_hdr_l);
                    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] rlc_hdr_l=%0d, rlc_pkt is \n%s", tb_idx, dl_node0.lcid, jj, rlc_hdr_l, rlc_pkt.sprint()), UVM_MEDIUM)            
                    if(encoder_hdr == 'h2) begin
                        pdcp_pkt.pack_hdr(normal_hdr_q[jj-mce_num], pdcp_hdr_l);
                        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] pdcp_hdr_l=%0d, pdcp_pkt is \n%s", tb_idx, dl_node0.lcid, jj, pdcp_hdr_l, pdcp_pkt.sprint()), UVM_MEDIUM)            
                        if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present != nr_l2dl_lc_cfg::NO_HDR)begin 
                            sdap_pkt.pack_hdr(normal_hdr_q[jj-mce_num], sdap_hdr_l);
                            `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] sdap_hdr_l=%0d, sdap_pkt is \n%s", tb_idx, dl_node0.lcid, jj, sdap_hdr_l, sdap_pkt.sprint()), UVM_MEDIUM)            
                        end
                        else begin
                            sdap_hdr_l = 'h0;
                        end
                    end
                    else if(encoder_hdr == 'h3) begin
                        if(dl_node0.si == 'h0)begin
                            pdcp_pkt.pack_hdr(normal_pld_q[jj-mce_num], pdcp_hdr_l);
                            sdap_hdr_l = 'h0;
                            `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] normal_pld_q.size=%0d, pdcp_hdr_l=%0d, pdcp_pkt is \n%s", tb_idx, dl_node0.lcid, jj, normal_pld_q[jj-mce_num].size(), pdcp_hdr_l, pdcp_pkt.sprint()), UVM_MEDIUM)            
                        end
                        else begin
                            pdcp_pkt.pack_hdr(seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn], pdcp_hdr_l);
                            `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] seg_pld_q[%0d][%0d].size()=%0d, pdcp_hdr_l=%0d, pdcp_pkt is \n%s", tb_idx, dl_node0.lcid, jj, dl_node0.lcid, dl_node0.rlc_sn, seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn].size(), pdcp_hdr_l, pdcp_pkt.sprint()), UVM_MEDIUM)            
                            if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].sdap_hdr_present != nr_l2dl_lc_cfg::NO_HDR)begin 
                                sdap_pkt.pack_hdr(seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn], sdap_hdr_l);
                                `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] seg_pld_q[%0d][%0d].size()=%0d, sdap_hdr_l=%0d, sdap_pkt is \n%s", tb_idx, dl_node0.lcid, jj, dl_node0.lcid, dl_node0.rlc_sn, seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn].size(), sdap_hdr_l, sdap_pkt.sprint()), UVM_MEDIUM)            
                            end
                            else begin
                                sdap_hdr_l = 'h0;
                            end
                        end
                    end
                end
                else if(encoder_hdr == 'h0)begin
                    mac_pkt.pack_hdr(0, normal_pld_q[jj-mce_num], mac_hdr_l);
                    rlc_hdr_l='h0;
                    pdcp_hdr_l='h0;
                    sdap_hdr_l='h0;
                    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] mac_hdr_l=%0d, mac_pkt is \n%s", tb_idx, dl_node0.lcid, jj, mac_hdr_l, mac_pkt.sprint()), UVM_MEDIUM)            
                    if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rlc_mode != nr_l2dl_lc_cfg::RLC_TM)begin
                        rlc_pkt.pack_hdr(normal_pld_q[jj-mce_num], rlc_hdr_l);
                        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] rlc_hdr_l=%0d, rlc_pkt is \n%s", tb_idx, dl_node0.lcid, jj, rlc_hdr_l, rlc_pkt.sprint()), UVM_MEDIUM)            
                    end
                end
                //dl_node0
                if(dl_node0.assemble_success == 'h1) begin
                    if(dl_node0.pdcp_dc == 'h0)begin
                        dl_node0.des_addr=seg_pld_addr[dl_node0.lcid][dl_node0.rlc_sn];
                    end else if(dl_node0.pdcp_dc == 'h1)begin 
                        if(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1)begin
                            dl_node0.des_addr=seg_pld_8cp_addr[dl_node0.lcid][dl_node0.rlc_sn] + pdcp_hdr_l + sdap_hdr_l;
                        end else begin
                            dl_node0.des_addr=seg_pld_addr[dl_node0.lcid][dl_node0.rlc_sn] + pdcp_hdr_l + sdap_hdr_l;
                        end
                    end
                end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG) begin
                    dl_node0.des_addr=seg_pld_addr[dl_node0.lcid][dl_node0.rlc_sn];
                end else begin
                    start_addr_vmem_cfg(dl_node0.data_byte_len,pload_addr);//pload_addr
                    dl_node0.des_addr=pload_addr;
                end

                void'(dl_node0.pack_bytes(node_data, default_packer));
                foreach(node_data[ii]) begin
                    dl_node0_byte_q.push_back(node_data[ii]);
                end

                if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG) && (m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].seg_num == seg_pkt_pool[dl_node0.lcid][dl_node0.rlc_sn].size()+'h1)) begin
                    pload_s = reassembly_length - pdcp_hdr_l - sdap_hdr_l - 4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present;
                    pload_pkt.pack_hdr(pload_s,seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn]);
                    //save normal pload data
                    pload_data = new[reassembly_length];
                    foreach(pload_data[ii]) begin
                        pload_data[ii] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][ii]; 
                    end
                    write_ddr_bytes(seg_pld_addr[dl_node0.lcid][dl_node0.rlc_sn], pload_data);
                    pload_data.delete();
                    if((m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.asmb_seg_type == 'h1) && (asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn] == 'h1) && (m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1))begin
                        //add 8byte cp_hdr data
                        cp_hdr = {10'h0,dl_node0.qfi,m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_id,16'h0,pload_s}; 
                        pload_data = new[reassembly_length+8];
                        for(int ii=0; ii<pdcp_hdr_l + sdap_hdr_l; ii++) begin
                            pload_data[ii] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][ii]; 
                        end
                        for(int ii=pdcp_hdr_l + sdap_hdr_l; ii<8+pdcp_hdr_l + sdap_hdr_l; ii++) begin
                            pload_data[ii] = cp_hdr[8*(ii-pdcp_hdr_l-sdap_hdr_l) +:8]; 
                        end
                        for(int ii=8+pdcp_hdr_l + sdap_hdr_l; ii<reassembly_length+8; ii++) begin
                            pload_data[ii] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][ii-8]; 
                        end
                        write_ddr_bytes(seg_pld_8cp_addr[dl_node0.lcid][dl_node0.rlc_sn], pload_data);
                        pload_data.delete();
                    end
                end else if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type != rx_mac_dl_node0_pkt_cfg::RLC_SEG) begin
                    pload_s = mac_pkt.l - (rlc_hdr_l + pdcp_hdr_l + sdap_hdr_l);
                    pload_pkt.pack_hdr(pload_s,normal_pld_q[jj-mce_num]);
                    //save normal pload data
                    if((encoder_hdr == 'h2)&&(m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].cp_header_en == 'h1))begin
                        cp_hdr = {10'h0,dl_node0.qfi,m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].rb_id,8'h0,dl_node0.data_byte_len-8}; 
                        pload_data = new[pload_s+8];
                        for(int ii=0; ii<8; ii++) begin
                            pload_data[ii] = cp_hdr[8*ii +:8]; 
                        end
                        for(int ii=0; ii<pload_s; ii++) begin
                            pload_data[ii+8] = normal_pld_q[jj-mce_num][ii]; 
                        end
                    end else if(encoder_hdr == 'h0)begin
                        pload_data = new[pload_s+rlc_hdr_l];
                        foreach(pload_data[ii]) begin
                            pload_data[ii] = normal_pld_q[jj-mce_num][ii+mac_hdr_l]; 
                        end
                    end else if(encoder_hdr == 'h3)begin
                        pload_data = new[pload_s+pdcp_hdr_l];
                        foreach(pload_data[ii]) begin
                            pload_data[ii] = normal_pld_q[jj-mce_num][ii]; 
                        end
                    end else begin
                        pload_data = new[pload_s];
                        foreach(pload_data[ii]) begin
                            pload_data[ii] = normal_pld_q[jj-mce_num][ii]; 
                        end
                    end
                    write_ddr_bytes(pload_addr, pload_data);
                    pload_data.delete();
                end
                if((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::SDAP_DATA) || ((m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG)&&(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.asmb_seg_type == 'h1)&&(asmb_seg_pdcp_dc[dl_node0.lcid][dl_node0.rlc_sn] == 'h1)))begin
                    m_nr_l2dl_env_cfg.tb_size[tb_idx] = m_nr_l2dl_env_cfg.tb_size[tb_idx] + mac_hdr_l + mac_pkt.l + 4*m_nr_l2dl_env_cfg.lc_cfg[dl_node0.lcid].int_present;  
                end else begin
                    m_nr_l2dl_env_cfg.tb_size[tb_idx] = m_nr_l2dl_env_cfg.tb_size[tb_idx] + mac_hdr_l + mac_pkt.l;  
                end

                if(m_nr_l2dl_env_cfg.normal_pkt_cfg[jj-mce_num].pkt_type == rx_mac_dl_node0_pkt_cfg::RLC_SEG) begin
                    foreach(seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n]) begin
                        if(n%8 == 0)       byte_8[ 7:0] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];       
                        else if(n%8 == 1)  byte_8[15:8] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];
                        else if(n%8 == 2)  byte_8[23:16] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];
                        else if(n%8 == 3)  byte_8[31:24] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];
                        else if(n%8 == 4)  byte_8[39:32] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];
                        else if(n%8 == 5)  byte_8[47:40] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];
                        else if(n%8 == 6)  byte_8[55:48] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];
                        else if(n%8 == 7)  byte_8[63:56] = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn][n];
                        if((n%8 == 7) || (n == seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn].size() - 1)) begin
                            idx = $ceil(n/8);
                            L2RegConfig.DataInfo[kk].dataAddr[idx] = byte_8;//
                            `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] seg_pld_q[%0d][%0d].size()=%0d, normal_pld_8[%0d]=%0h", tb_idx, dl_node0.lcid, jj, dl_node0.lcid, dl_node0.rlc_sn, seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn].size(), jj-mce_num, byte_8), UVM_DEBUG)
                            byte_8 = 'h0;
                        end
                    end
                    L2RegConfig.DataInfo[kk].dataLen = seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn].size();//payloade1 length max 1500byte
                    if(seg_pkt_pool[dl_node0.lcid][dl_node0.rlc_sn].size()=='h0)begin
                       seg_pld_q[dl_node0.lcid][dl_node0.rlc_sn].delete(); 
                    end
                end else begin
                    foreach(normal_pld_q[jj-mce_num][n]) begin
                        if(n%8 == 0)       byte_8[ 7:0] = normal_pld_q[jj-mce_num][n];       
                        else if(n%8 == 1)  byte_8[15:8] = normal_pld_q[jj-mce_num][n];
                        else if(n%8 == 2)  byte_8[23:16] = normal_pld_q[jj-mce_num][n];
                        else if(n%8 == 3)  byte_8[31:24] = normal_pld_q[jj-mce_num][n];
                        else if(n%8 == 4)  byte_8[39:32] = normal_pld_q[jj-mce_num][n];
                        else if(n%8 == 5)  byte_8[47:40] = normal_pld_q[jj-mce_num][n];
                        else if(n%8 == 6)  byte_8[55:48] = normal_pld_q[jj-mce_num][n];
                        else if(n%8 == 7)  byte_8[63:56] = normal_pld_q[jj-mce_num][n];
                        if((n%8 == 7) || (n == normal_pld_q[jj-mce_num].size() - 1)) begin
                            idx = $ceil(n/8);
                            L2RegConfig.DataInfo[kk].dataAddr[idx] = byte_8;//
                            `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_normal_pkt_lcid[%0d]_node[%0d] normal_pld_q[%0d].size()=%0d, normal_pld_8[%0d]=%0h", tb_idx, dl_node0.lcid, jj, jj-mce_num, normal_pld_q[jj-mce_num].size(), jj-mce_num, byte_8), UVM_DEBUG)
                            byte_8 = 'h0;
                        end
                    end
                    L2RegConfig.DataInfo[kk].dataLen = normal_pld_q[jj-mce_num].size();//payloade1 length max 1500byte
                end
            end
            L2RegConfig.DTCNode[jj].firstptr = jj*continuous_data_num;
            acc_pdcp_sn = dl_node0.pdcp_sn; 
            acc_rlc_sn = dl_node0.rlc_sn; 
            //colletc dl_node0 coverage
            m_nr_l2dl_coverage.sample_dl_node0(dl_node0);
        end
    end

    for(int ii= normal_node_num+mce_num; ii<normal_node_num+mce_num+padding_num; ii++) begin
        l_max_value = l_max_value - padding_byte_q.size();

        assert(mac_pkt.randomize() with {
            mc_type inside {mac_padding};
        });
        assert(pload_pkt.randomize());
        if(l_max_value<1000)begin
            pload_s = $urandom_range(10,10+l_max_value);
        end else begin
            pload_s = $urandom_range(10,1000);
        end
        mac_pkt.pack_hdr(0, padding_byte_q, mac_hdr_l);
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_padding_pkt mac_hdr_l=%0d, mac_pkt is \n%s", tb_idx, mac_hdr_l, mac_pkt.sprint()), UVM_MEDIUM)
        pload_pkt.pack_hdr(pload_s,padding_byte_q);
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_padding_pkt pload_s=%0d, mac_pkt.l=%0d", tb_idx, pload_s, mac_pkt.l), UVM_MEDIUM)
        m_nr_l2dl_env_cfg.tb_size[tb_idx] = m_nr_l2dl_env_cfg.tb_size[tb_idx] + mac_hdr_l + pload_s;  

        L2RegConfig.DTCNode[ii].continuousDataNum = 1; //=1
        L2RegConfig.DTCNode[ii].RbDirInfo = 'h0;
        L2RegConfig.DTCNode[ii].controlbits = 'hb00;// (destination<<11)|(encoderheader<<6|lcid);
        L2RegConfig.DTCNode[ii].StartCount = 'h0;
        L2RegConfig.DTCNode[ii].sdapheader = 1;
        L2RegConfig.DTCNode[ii].offset = 0;
        L2RegConfig.DTCNode[ii].StartRlcSn = 'h0;
        L2RegConfig.DTCNode[ii].rlcpdcpbits = 'h0;//(SI&0x03)|(POLL<<2);
        L2RegConfig.DTCNode[ii].SoStart =0;
        L2RegConfig.DTCNode[ii].SegmentLength =0;
        L2RegConfig.DTCNode[ii].next = (ii == `RX_MAC_ENTITY_NUM*normal_node_num+mce_num+padding_num - 1) ? 0 : ii+1;
        for(int jj=ii; jj<ii+1; jj++) begin
            foreach(padding_byte_q[kk]) begin
                if(kk%8 == 0)       byte_8[7:0] = padding_byte_q[kk];       
                else if(kk%8 == 1)  byte_8[15:8] = padding_byte_q[kk];
                else if(kk%8 == 2)  byte_8[23:16] = padding_byte_q[kk];
                else if(kk%8 == 3)  byte_8[31:24] = padding_byte_q[kk];
                else if(kk%8 == 4)  byte_8[39:32] = padding_byte_q[kk];
                else if(kk%8 == 5)  byte_8[47:40] = padding_byte_q[kk];
                else if(kk%8 == 6)  byte_8[55:48] = padding_byte_q[kk];
                else if(kk%8 == 7)  byte_8[63:56] = padding_byte_q[kk];
                if((kk%8 == 7) || (kk == padding_byte_q.size() - 1)) begin
                    idx = $ceil(kk/8);
                    L2RegConfig.DataInfo[jj].dataAddr[idx] = byte_8;//
                    `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_padding_pkt_node[%0d] padding_byte_q.size()=%0d, padding_byte_8=%0h", tb_idx, ii, padding_byte_q.size(), byte_8), UVM_DEBUG)
                    byte_8 = 'h0;
                end
            end
            L2RegConfig.DataInfo[jj].dataLen = padding_byte_q.size();//payloade1 length max 1500byte
        end
        L2RegConfig.DTCNode[ii].firstptr = ii;

        //save normal pload data
        pload_data = new[pload_s];
        foreach(pload_data[ii]) begin
            pload_data[ii] = padding_byte_q[ii+1]; 
        end

        //acc_node
        assert(acc_node.randomize() with{
            lcid==mac_pkt.lcid;
            sdu_type[5] == 1'b1;//padding
            sdu_type[4:0] == 'h0;
            sdu_type[15:6] == 'h0;
            total_sdu_len== 'h0;
            first_l2dl_node_idx == 'h0;
            first_l2dl_ptr_idx == 'h0;
            l2_node_num == 'h0; 
        });
        tb_acc_num++;
        void'(acc_node.pack_bytes(node_data, default_packer));
        foreach(node_data[ii]) begin
            acc_node_byte_q.push_back(node_data[ii]);
        end
        node_data.delete();
    end

    if(m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.tb_dbgout_en == 1'h1)begin
        pload_data = new[m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len];
        for(int ii=0; ii<mce_num; ii++)begin
            for(int jj=0; jj<mce_byte_q[ii].size(); jj++)begin
                if(dbg_idx<=m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len) begin
                    pload_data[dbg_idx] = mce_byte_q[ii][jj];
                    dbg_idx=dbg_idx+1;
                end else begin
                    break;
                end
            end
        end
        write_ddr_bytes(m_nr_l2dl_env_cfg.dbg_out_addr+(tb_idx-`TB_IDX)*m_nr_l2dl_env_cfg.m_rx_mac_reg_cfg.dbg_out_len, pload_data);
        pload_data.delete();
    end
endtask : set_nr_l2_reg_cfg

task nr_l2dl_init_seq::cfg_gen();
    foreach(mce_cfg[ii]) begin
        mce_cfg[ii] = nr_l2dl_mce_cfg::type_id::create($sformatf("mce_cfg[%0d]", ii));
        if((ii+33) inside {mce_fixed_lcid_q}) begin
            assert(mce_cfg[ii].randomize() with {
                lcid_valid == 1;
                fix_length == 1;
                if(ii+33==47) length == 2;
                else if(ii+33==48) length == 2;
                else if(ii+33==49) length == 3;
                else if(ii+33==51) length == 2;
                else if(ii+33==52) length == 2;
                else if(ii+33==56) length == 1;
                else if(ii+33==57) length == 4;
                else if(ii+33==58) length == 1;
                else if(ii+33==59) length == 0;
                else if(ii+33==60) length == 0;
                else if(ii+33==61) length == 1;
                else if(ii+33==62) length == 6;
            }) else  `uvm_error(get_full_name(), "mce cfg generator randomize failed")
        end
        else if((ii+33) inside {mce_nonfixed_lcid_q}) begin
            assert(mce_cfg[ii].randomize() with {
                lcid_valid == 1;
                fix_length == 0;
            }) else  `uvm_error(get_full_name(), "mce cfg generator randomize failed")
        end
        else if((ii+33) inside {[33:46], 63}) begin
            assert(mce_cfg[ii].randomize()) else  `uvm_error(get_full_name(), "mce cfg generator randomize failed")
        end
    end
endtask : cfg_gen

task nr_l2dl_init_seq::id_gen();
    bit  [5:0]  lcid_47_62_q[$];
    bit  [5:0]  lcid_1_32_q[$];
    int         fixed_num, nonfixed_num;
    //mce_type
    for(int ii = 47; ii <= 62; ii++) begin
        if(ii inside {50,53,54,55}) begin
            mce_nonfixed_lcid_q.push_back(ii);
        end
        else begin
        mce_fixed_lcid_q.push_back(ii);
        end
    end
    mce_nonfixed_lcid_q.shuffle();
    mce_fixed_lcid_q.shuffle();
endtask : id_gen

task nr_l2dl_init_seq::start_addr_vmem_cfg(int data_len, output bit [31:0] data_addr);
    uvm_mem_region mem_data_region;
    
    mem_data_region = m_nr_l2dl_env_cfg.ddr_mem.mam.request_region(data_len, m_nr_l2dl_env_cfg.ddr_mem_policy);
    if(mem_data_region == null) begin
        `uvm_error(get_full_name(), $sformatf("fail to request %0d byte for virtual memory", data_len))
    end
    
    data_addr = mem_data_region.get_start_offset() + m_nr_l2dl_env_cfg.ddr_mem_base;
endtask : start_addr_vmem_cfg

task nr_l2dl_init_seq::write_node(ref bit [7:0] l1_mce_node_byte_q[$], ref bit [7:0] l2_mce_node_byte_q[$], ref bit [7:0] dl_node0_byte_q[$], ref bit [7:0] acc_node_byte_q[$]);
    bit bit_stream[];

    bit [31:0] node_dma_addr;
    bit [ 7:0] node_data[];

    if(l1_mce_node_byte_q.size()>0) begin
        node_data = new[l1_mce_node_byte_q.size()];
        foreach(node_data[ii]) begin
           node_data[ii] =  l1_mce_node_byte_q[ii];
        end
        write_ddr_bytes(m_nr_l2dl_env_cfg.macce_node1_dma_addr+l1_mce_num*8, node_data);
        l1_mce_num = l1_mce_num + l1_mce_node_byte_q.size()/8; 
        node_data.delete();
    end 
    if(l2_mce_node_byte_q.size()>0) begin
        node_data = new[l2_mce_node_byte_q.size()];
        foreach(node_data[ii]) begin
           node_data[ii] =  l2_mce_node_byte_q[ii];
        end
        write_ddr_bytes(m_nr_l2dl_env_cfg.macce_node2_dma_addr+l2_mce_num*8, node_data);
        l2_mce_num = l2_mce_num + l2_mce_node_byte_q.size()/8; 
        node_data.delete();
    end 
    if(dl_node0_byte_q.size()>0) begin
        node_data = new[dl_node0_byte_q.size()];
        foreach(node_data[ii]) begin
           node_data[ii] =  dl_node0_byte_q[ii];
        end
        //------------TODO debug--------------------------//
        for(int ii=0; ii<dl_node0_byte_q.size()/32; ii++)begin
            bit_stream = new[256];
            for(int jj=0; jj<31; jj++)begin
                for(int kk=0; kk<8; kk++)begin
                    bit_stream[8*jj+kk] = dl_node0_byte_q[32*ii+jj][kk];
                end
            end
            void'(exp_dl_node0.unpack(bit_stream, default_packer));
            `uvm_info($sformatf("%25s", get_full_name()), $sformatf("exp_dl_node0 is \n%s", exp_dl_node0.sprint()), UVM_DEBUG)
        end
        //------------debug--------------------------//
        write_ddr_bytes(m_nr_l2dl_env_cfg.dl_node0_dma_addr+l2_node0_num*32, node_data);
        l2_node0_num = l2_node0_num + dl_node0_byte_q.size()/32; 
        node_data.delete();
        dl_node0_byte_q.delete();
    end 
    if(acc_node_byte_q.size()>0) begin
        node_data = new[acc_node_byte_q.size()];
        foreach(node_data[ii]) begin
           node_data[ii] =  acc_node_byte_q[ii];
        end
        write_ddr_bytes(m_nr_l2dl_env_cfg.acc_node_dma_addr+l2_acc_num*16, node_data);
        acc_node_byte_q.delete();
        node_data.delete();
    end 
endtask : write_node

task nr_l2dl_init_seq::tb_info_gen(input bit [6:0] tb_idx);
    bit [7:0]  tb_info_data[];

    `uvm_create(l1_tb_info)
    `uvm_create(l2_tb_info)
    
    begin
        assert(l1_tb_info.randomize() with{
            first_mce_node_idx == l1_mce_num - l1_mce_node_byte_q.size()/8;
            mce_node_num == l1_mce_node_byte_q.size()/8;
            cellgroup == m_nr_l2dl_env_cfg.cellgroup;
            cellindex == m_nr_l2dl_env_cfg.cellindex;
            cursfn == m_nr_l2dl_env_cfg.cursfn;
            cursubsfn == m_nr_l2dl_env_cfg.cursubsfn;
            slot == tb_idx; 
            scs == m_nr_l2dl_env_cfg.scs;
            harqid == m_nr_l2dl_env_cfg.harqid;
        });

        void'(l1_tb_info.pack_bytes(tb_info_data, default_packer));
        //if(m_nr_l2dl_env_cfg.tb_info1_space >= tb_idx+1) begin 
            write_ddr_bytes(m_nr_l2dl_env_cfg.tb_info1_dma_addr + tb_idx*16, tb_info_data);
        //end
        //else begin
        //    write_ddr_bytes(m_nr_l2dl_env_cfg.tb_info1_dma_addr + (((tb_idx+1)%(m_nr_l2dl_env_cfg.tb_info1_space)) - 1)*16, tb_info_data);
        //end
        //l1_mce_num = 0;
        tb_info_data.delete();
        l1_mce_node_byte_q.delete();
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_l1_tb_info is \n%s", tb_idx, l1_tb_info.sprint()), UVM_DEBUG)

        assert(l2_tb_info.randomize() with{
            dbg_out_addr == m_nr_l2dl_env_cfg.dbg_out_addr;
            first_l2dl_node_out_idx == tb_idx*m_nr_l2dl_env_cfg.normal_node_num;
            l2dl_node_num == m_nr_l2dl_env_cfg.normal_node_num;
            first_l2_acc_idx == l2_acc_num;
            nr_l2_acc_num == tb_acc_num;
            first_mce_node_idx == l2_mce_num - l2_mce_node_byte_q.size()/8;
            mce_node_num == l2_mce_node_byte_q.size()/8;
            cellgroup == m_nr_l2dl_env_cfg.cellgroup;
            cellindex == m_nr_l2dl_env_cfg.cellindex;
            cursfn == m_nr_l2dl_env_cfg.cursfn;
            cursubsfn == m_nr_l2dl_env_cfg.cursubsfn;
            slot == tb_idx; 
            scs == m_nr_l2dl_env_cfg.scs;
            harqid == m_nr_l2dl_env_cfg.harqid;
            dtc_chk_err == 'h0;
        });
        void'(l2_tb_info.pack_bytes(tb_info_data, default_packer));
        //if(m_nr_l2dl_env_cfg.tb_info2_space >= tb_idx+1) begin 
            write_ddr_bytes(m_nr_l2dl_env_cfg.tb_info2_dma_addr + tb_idx*32, tb_info_data);
        //end
        //else begin
        //    write_ddr_bytes(m_nr_l2dl_env_cfg.tb_info2_dma_addr + (((tb_idx+1)%(m_nr_l2dl_env_cfg.tb_info2_space)) - 1)*32, tb_info_data);
        //end
        l2_acc_num = l2_acc_num + tb_acc_num; 
        tb_acc_num = 0;
        tb_info_data.delete();
        l2_mce_node_byte_q.delete();
        `uvm_info($sformatf("%25s", get_full_name()), $sformatf("tb[%0d]_l2_tb_info is \n%s", tb_idx, l2_tb_info.sprint()), UVM_DEBUG)
    end
endtask : tb_info_gen 

task nr_l2dl_init_seq::random_sn_seg_na_discard_proc(input[5:0] lc_id, input [17:0] sn, input int unsigned seg_number, input int unsigned pdu_reassembly_length);
    int unsigned so_end;
    int unsigned last_so_end_q[$];

    rx_mac_seg_pkt_info seg_pkt_even_pool[`RX_MAC_ENTITY_NUM][int unsigned][$];
    rx_mac_seg_pkt_info seg_pkt_odd_pool[`RX_MAC_ENTITY_NUM][int unsigned][$];

    for(int ii=0; ii<seg_number; ii++)begin
        rx_mac_seg_pkt_info seg_pkt_info;
        seg_pkt_info = rx_mac_seg_pkt_info::type_id::create("seg_pkt_info"); 
        if(last_so_end_q.size() !=0)begin
            so_end=last_so_end_q.pop_front();
        end
        assert(seg_pkt_info.randomize() with {
            rlc_so inside {[0:pdu_reassembly_length]};
            rlc_pdu_length inside {[1:pdu_reassembly_length]};
            if(ii==0){
                rlc_so == 0;
                rlc_so + rlc_pdu_length inside {[1:pdu_reassembly_length-seg_number]};
                rlc_si == 2'b01;
            }
            else if(ii==seg_number-1){
                rlc_so == so_end;
                //rlc_so inside {[so_end-5:so_end]};
                rlc_so + rlc_pdu_length == pdu_reassembly_length;
                rlc_si == 2'b10;
            }
            else{
                rlc_so == so_end;
                //rlc_so inside {[so_end-1:so_end]};
                rlc_so + rlc_pdu_length inside {[1:pdu_reassembly_length-seg_number+ii]};
                rlc_si == 2'b11;
            }
        })
        last_so_end_q.push_back(seg_pkt_info.rlc_so+seg_pkt_info.rlc_pdu_length);

        if(ii%2 == 0)begin
            seg_pkt_even_pool[lc_id][sn].push_back(seg_pkt_info);
        end else begin
            seg_pkt_odd_pool[lc_id][sn].push_back(seg_pkt_info);
        end
    end
    seg_pkt_even_pool[lc_id][sn].shuffle();
    seg_pkt_odd_pool[lc_id][sn].shuffle();

    foreach(seg_pkt_even_pool[lc_id][sn][ii])begin
        seg_pkt_pool[lc_id][sn].push_back(seg_pkt_even_pool[lc_id][sn][ii]);
    end
    foreach(seg_pkt_odd_pool[lc_id][sn][ii])begin
        seg_pkt_pool[lc_id][sn].push_back(seg_pkt_odd_pool[lc_id][sn][ii]);
    end
endtask : random_sn_seg_na_discard_proc 


//: nr_l2dl_init_seq
 
`endif
