typedef enum {
    NR_L2DL_STREAM_NONE = 0,
    NR_L2DL_IN = 1000,
    L1_MCE_NODE = 1001,
    L2_MCE_NODE = 1002,
    DL_NODE0 = 1003,
    DMA_L1_MCE_NODE = 1004,
    DMA_L2_MCE_NODE = 1005,
    DMA_DL_NODE0 = 1006,
    DMA_L1_TB_INFO = 1007,
    DMA_L2_TB_INFO = 1008,
    DTC_PLD = 1009,
    DTC_DMA = 1010,
    DMA_DL_NODE0_PLD = 1011,
    DMA_L1_MCE_PLD   = 1012,
    DMA_L2_MCE_PLD   = 1013,
    DMA_ACC_NODE = 1014,
    TB_INFO1_DMA = 1015,
    TB_INFO2_DMA = 1016,
    MCE_NODE1_DMA = 1017,
    MCE_NODE2_DMA = 1018,
    MCE_PLD_DMA = 1019,
    DL_NODE0_DMA = 1020,
    DL_NODE0_PLD_DMA = 1021,
    ACC_NODE_DMA = 1022,
    DL_NODE0_ACC = 1023,
    PS_DL_RLC_PREPROC_VAR = 1100,
    PS_DL_RLC_PREPROC_VAR_END = 1131
} NR_L2DL_SCB_STREAM_ID_T;

typedef struct
{
    longint LCID;
    longint RBid;
    longint isSrb;
    longint UlrlcMode;
    longint UlrlcSnLength;
    longint UlPdcpSnLength;
    longint UlSdapheaderPresent;
    longint isUlActive;
    longint DlrlcMode;
    longint DlrlcSnLength;
    longint DlPdcpSnLength;
    longint DlSdapheaderPresent;
    longint isDlActive;
    longint Softdecipherandintegrity;
    longint L2headerIntervalPresent; 
    longint PdcpSduIntervalSizeReserved;
    longint DlPdcpWindowSize;
    longint cipAlgo;
    longint cipherPresent;
    longint intAlgo;
    longint integrityPresent;
    longint reserved1;
    longint reserved2;
    longint reserved3;
    longint KeyEnc[4]; 
    longint KeyInt[4];
}NrLogicalChannelConfigTable;

typedef struct
{
    longint next;
    longint continuousDataNum; 
    longint RbDirInfo;
    longint controlbits;
    longint firstptr;
    longint StartCount;
    longint SoStart;
    longint sdapheader;
    longint rlcpdcpbits;
    longint StartRlcSn;
    longint SegmentLength;
    longint offset;
}NRDtccr;

typedef struct
{
    longint dataLen; 
    longint dataAddr[199];
}NrDataInfo;

typedef struct
{
    longint fileindex;
    longint SegmentType;//0 or 1 hw do rlc assemble? 
    longint LogicChannelNum;
    longint Lcid[34];
    NrLogicalChannelConfigTable nrLogicalChannelConfigTable[34];
    longint RX_DELIV[34];
    longint reserved1;
    longint DtcNodeNum;//ul dtc node
    NRDtccr DTCNode[200];//ul dtc node
    NrDataInfo DataInfo[500];//ul ip data ptr
}NrL2RegConfig;

//basic SCB item
class nr_l2dl_base_trans extends uvm_sequence_item;
    NR_L2DL_SCB_STREAM_ID_T stream_id;
    `uvm_object_utils_begin(nr_l2dl_base_trans)
        `uvm_field_enum(NR_L2DL_SCB_STREAM_ID_T, stream_id, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_object_utils_end
    function new(string name="nr_l2dl_base_trans");
        super.new(name);
    endfunction : new
endclass : nr_l2dl_base_trans

class nr_l2dl_fifo_trans extends nr_l2dl_base_trans;
    rand int delay;
    rand int ch_id;
    `uvm_object_utils_begin(nr_l2dl_fifo_trans)
        `uvm_field_int(delay, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
        `uvm_field_int(ch_id, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_object_utils_end
    function new(string name="nr_l2dl_fifo_trans");
        super.new(name);
    endfunction : new

    constraint delay_cons {delay inside {[1:10]};}
endclass : nr_l2dl_fifo_trans

typedef nr_l2dl_fifo_trans asr_src_fifo_trans;
typedef nr_l2dl_fifo_trans asr_dst_fifo_trans;

class default_packer_t extends uvm_packer;
    function new();
        super.new();
        super.big_endian = 0;
    endfunction : new
endclass : default_packer_t

static default_packer_t default_packer = new;

class rx_mac_tb_cmd_trans extends nr_l2dl_fifo_trans;
    rand bit [17:0] tb_size; // tb byte num
    rand bit [1:0]  cellgroup;
    rand bit [4:0]  cellindex;
    rand bit [3:0]  subsfn;
    rand bit [11:0] sfn;
    rand bit [2:0]  scs;
    //rand bit [4:0]  harqid; //process id
    `uvm_object_utils_begin(rx_mac_tb_cmd_trans)
        `uvm_field_int(tb_size, UVM_DEFAULT)
        `uvm_field_int(cellgroup, UVM_DEFAULT)
        `uvm_field_int(cellindex, UVM_DEFAULT)
        `uvm_field_int(subsfn, UVM_DEFAULT)
        `uvm_field_int(sfn, UVM_DEFAULT)
        `uvm_field_int(scs, UVM_DEFAULT)
        //`uvm_field_int(harqid, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name="rx_mac_tb_cmd_trans");
        super.new(name);
    endfunction : new
endclass : rx_mac_tb_cmd_trans

class rx_mac_tb_top_info_node extends nr_l2dl_fifo_trans;
    rand bit [31:0] mac_tb_start_addr;
    rand bit [31:0] mac_tb_length;
    `uvm_object_utils_begin(rx_mac_tb_top_info_node)
        `uvm_field_int(mac_tb_start_addr, UVM_DEFAULT)
        `uvm_field_int(mac_tb_length, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name="rx_mac_tb_top_info_node");
        super.new(name);
    endfunction : new

endclass : rx_mac_tb_top_info_node

class rx_mac_dl_node1 extends nr_l2dl_fifo_trans;
    rand bit [31:0] addr;

    constraint tb_info_drv_delay {
        delay inside {[1:100]};
    }
    `uvm_object_utils_begin(rx_mac_dl_node1)
        `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name="rx_mac_dl_node1");
        super.new(name);
    endfunction : new

endclass : rx_mac_dl_node1

class nr_l2dl_dtc_pld_trans extends nr_l2dl_fifo_trans;
    rand bit [ 31:0] addr;
    rand bit [127:0] data;
    `uvm_object_utils_begin(nr_l2dl_dtc_pld_trans)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(addr, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_object_utils_end
    function new(string name="nr_l2dl_dtc_pld_trans");
        super.new(name);
    endfunction : new

endclass : nr_l2dl_dtc_pld_trans

typedef nr_l2dl_dtc_pld_trans nr_l2dl_dtc_rdma_trans; 

class rx_mac_l1_tb_info extends nr_l2dl_fifo_trans;
    rand bit [ 7:0]  first_mce_node_idx;
    rand bit [ 7:0]  mce_node_num;
    rand bit [ 7:0]  cellgroup;
    rand bit [ 7:0]  cellindex;
    rand bit [15:0]  cursfn;
    rand bit [15:0]  cursubsfn;
    rand bit [ 7:0]  slot;
    rand bit [ 7:0]  scs;
    rand bit [ 7:0]  harqid; //process id
    rand bit [39:0]  rsvd;
    `uvm_object_utils_begin(rx_mac_l1_tb_info)
        `uvm_field_int(first_mce_node_idx, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(mce_node_num, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(cellgroup, UVM_DEFAULT)
        `uvm_field_int(cellindex, UVM_DEFAULT)
        `uvm_field_int(cursfn, UVM_DEFAULT)
        `uvm_field_int(cursubsfn, UVM_DEFAULT)
        `uvm_field_int(slot, UVM_DEFAULT)
        `uvm_field_int(scs, UVM_DEFAULT)
        `uvm_field_int(harqid, UVM_DEFAULT) //process id
        `uvm_field_int(rsvd, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_object_utils_end
    function new(string name="rx_mac_l1_tb_info");
        super.new(name);
    endfunction : new

endclass : rx_mac_l1_tb_info

class rx_mac_l2_tb_info extends nr_l2dl_fifo_trans;
    rand bit [31:0]  dbg_out_addr;
    rand bit [15:0]  first_l2dl_node_out_idx;
    rand bit [15:0]  l2dl_node_num;
    rand bit [15:0]  first_l2_acc_idx;
    rand bit [15:0]  nr_l2_acc_num;
    rand bit [ 7:0]  first_mce_node_idx;
    rand bit [ 7:0]  mce_node_num;
    rand bit [ 7:0]  cellgroup;
    rand bit [ 7:0]  cellindex;
    rand bit [15:0]  cursfn;
    rand bit [15:0]  cursubsfn;
    rand bit [ 7:0]  slot;
    rand bit [ 7:0]  scs;
    rand bit [ 7:0]  harqid; //process id
    rand bit [ 7:0]  dtc_chk_err;
    rand bit [63:0]  rsvd;
    `uvm_object_utils_begin(rx_mac_l2_tb_info)
        `uvm_field_int(dbg_out_addr, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(first_l2dl_node_out_idx, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(l2dl_node_num, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(first_l2_acc_idx, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(nr_l2_acc_num, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(first_mce_node_idx, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(mce_node_num, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(cellgroup, UVM_DEFAULT)
        `uvm_field_int(cellindex, UVM_DEFAULT)
        `uvm_field_int(cursfn, UVM_DEFAULT)
        `uvm_field_int(cursubsfn, UVM_DEFAULT)
        `uvm_field_int(slot, UVM_DEFAULT)
        `uvm_field_int(scs, UVM_DEFAULT)
        `uvm_field_int(harqid, UVM_DEFAULT) //process id
        `uvm_field_int(dtc_chk_err, UVM_DEFAULT)
        `uvm_field_int(rsvd, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_object_utils_end
    function new(string name="rx_mac_l2_tb_info");
        super.new(name);
    endfunction : new
endclass : rx_mac_l2_tb_info

class rx_mac_acc_node extends nr_l2dl_fifo_trans;
    rand bit [ 7:0]  lcid;
    rand bit [ 7:0]  l2_node_num;
    rand bit [15:0]  sdu_type;//0:normal_padcp(si=0); 1:rlc_seg(si!=0);2:rlc_ctrl;3:pdcp_ctrl;4:tm_sdu;5:padding;6:protocal_err;8:polling;9:rqi_or_rdi;11~15:error_type
    rand bit [15:0]  rsvd;
    rand bit [15:0]  first_l2dl_node_idx;
    rand bit [31:0]  first_l2dl_ptr_idx;
    rand bit [31:0]  total_sdu_len;
    `uvm_object_utils_begin(rx_mac_acc_node)
        `uvm_field_int(lcid, UVM_DEFAULT)
        `uvm_field_int(l2_node_num, UVM_DEFAULT)
        `uvm_field_int(sdu_type, UVM_DEFAULT)
        `uvm_field_int(rsvd, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(first_l2dl_node_idx, UVM_DEFAULT)
        `uvm_field_int(first_l2dl_ptr_idx, UVM_DEFAULT)
        `uvm_field_int(total_sdu_len, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name="rx_mac_acc_node");
        super.new(name);
    endfunction : new
endclass : rx_mac_acc_node

class rx_mac_dl_node0 extends nr_l2dl_fifo_trans;
    rand bit [ 7:0]  lcid;
    rand bit [15:0]  l;
    rand bit [ 7:0]  rlc_dc;
    rand bit [ 7:0]  polling;
    rand bit [ 7:0]  si;
    rand bit [15:0]  so;
    rand bit [31:0]  rlc_sn;
    rand bit [ 7:0]  dec_pdcp_hdr;
    rand bit [ 7:0]  assemble_success;
    rand bit [ 7:0]  pdcp_dc;
    rand bit [ 5:0]  qfi;
    rand bit         rqi;
    rand bit         rdi;
    rand bit [31:0]  pdcp_sn;
    rand bit [ 7:0]  decipher_pdcp_data;
    rand bit [ 7:0]  chk_err;
    rand bit [15:0]  data_byte_len;
    rand bit [31:0]  des_addr;
    rand bit [31:0]  rsvd;
    `uvm_object_utils_begin(rx_mac_dl_node0)
        `uvm_field_int(lcid, UVM_DEFAULT)
        `uvm_field_int(l, UVM_DEFAULT)
        `uvm_field_int(rlc_dc, UVM_DEFAULT)
        `uvm_field_int(polling, UVM_DEFAULT)
        `uvm_field_int(si, UVM_DEFAULT)
        `uvm_field_int(so, UVM_DEFAULT)
        `uvm_field_int(rlc_sn, UVM_DEFAULT)
        `uvm_field_int(dec_pdcp_hdr, UVM_DEFAULT)
        `uvm_field_int(assemble_success, UVM_DEFAULT)
        `uvm_field_int(pdcp_dc, UVM_DEFAULT)
        `uvm_field_int(qfi, UVM_DEFAULT)
        `uvm_field_int(rqi, UVM_DEFAULT)
        `uvm_field_int(rdi, UVM_DEFAULT)
        `uvm_field_int(pdcp_sn, UVM_DEFAULT)
        `uvm_field_int(decipher_pdcp_data, UVM_DEFAULT)
        `uvm_field_int(chk_err, UVM_DEFAULT)
        `uvm_field_int(data_byte_len, UVM_DEFAULT)
        `uvm_field_int(des_addr, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(rsvd, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_object_utils_end
    function new(string name="rx_mac_dl_node0");
        super.new(name);
    endfunction : new
endclass : rx_mac_dl_node0

class rx_mac_mce_node extends nr_l2dl_fifo_trans;
    rand bit [ 7:0]  rsvd;
    rand bit [ 7:0]  lcid;
    rand bit [15:0]  l;
    rand bit [31:0]  mce_start_addr;
    `uvm_object_utils_begin(rx_mac_mce_node)
        `uvm_field_int(rsvd, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(lcid, UVM_DEFAULT)
        `uvm_field_int(l, UVM_DEFAULT)
        `uvm_field_int(mce_start_addr, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_object_utils_end
    function new(string name="rx_mac_mce_node");
        super.new(name);
    endfunction : new
endclass : rx_mac_mce_node

typedef rx_mac_mce_node rx_mac_mce_trans; 
typedef rx_mac_dl_node0 rx_mac_dl_node0_trans; 
typedef rx_mac_dl_node0 rx_mac_dma_trans; 

task traverse_nr_l2dl_stream_name(output int unsigned stream_id[$], output string name[$]);
    NR_L2DL_SCB_STREAM_ID_T id = id.first();

    do begin
        stream_id.push_back(id);
        id = id.next();
    end while(id != id.first());

    for(int unsigned ii=PS_DL_RLC_PREPROC_VAR; ii<=PS_DL_RLC_PREPROC_VAR_END; ii++) begin
        stream_id.push_back(ii);
    end

    stream_id = stream_id.unique();

    foreach(stream_id[ii]) begin
        name.push_back(get_nr_l2dl_stream_name(stream_id[ii]));
    end
endtask: traverse_nr_l2dl_stream_name 

function string get_nr_l2dl_stream_name(NR_L2DL_SCB_STREAM_ID_T stream_id);
    if(stream_id >= PS_DL_RLC_PREPROC_VAR  && stream_id <= PS_DL_RLC_PREPROC_VAR_END) begin
        return ($sformatf("PS_DL_RLC_PREPROC_VAR%0d", stream_id-PS_DL_RLC_PREPROC_VAR));
    end
    else begin
        return stream_id.name();
    end
endfunction : get_nr_l2dl_stream_name 

class rx_mac_seg_pkt_info extends nr_l2dl_fifo_trans;
    rand bit [ 1:0]  rlc_si;
    rand bit [15:0]  rlc_so;
    rand bit [15:0]  rlc_pdu_length;
    `uvm_object_utils_begin(rx_mac_seg_pkt_info)
        `uvm_field_int(rlc_si, UVM_DEFAULT)
        `uvm_field_int(rlc_so, UVM_DEFAULT)
        `uvm_field_int(rlc_pdu_length, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name="rx_mac_seg_pkt_info");
        super.new(name);
    endfunction : new
endclass : rx_mac_seg_pkt_info

class rx_mac_dl_node0_pkt_cfg extends nr_l2dl_fifo_trans;
    typedef enum {
        ERR,
        SDAP_DATA,
        RLC_CTRL,
        RLC_SEG,
        RLC_TMD,
        PDCP_CTRL
    } PKT_TYPE_T;
    rand PKT_TYPE_T pkt_type;
    rand bit [ 7:0]  lcid;
    rand bit [ 7:0]  polling;
    rand bit [31:0]  rlc_sn;
    rand bit [31:0]  pdcp_sn;
    rand bit [ 7:0]  seg_num;
    `uvm_object_utils_begin(rx_mac_dl_node0_pkt_cfg)
        `uvm_field_int(lcid, UVM_DEFAULT)
        `uvm_field_int(polling, UVM_DEFAULT)
        `uvm_field_int(rlc_sn, UVM_DEFAULT)
        `uvm_field_int(pdcp_sn, UVM_DEFAULT)
        `uvm_field_int(seg_num, UVM_DEFAULT)
        `uvm_field_enum(PKT_TYPE_T, pkt_type, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name="rx_mac_dl_node0_pkt_cfg");
        super.new(name);
    endfunction : new
endclass : rx_mac_dl_node0_pkt_cfg
