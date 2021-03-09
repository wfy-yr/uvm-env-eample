class nr_l2dl_dtc_rdma_scb_transformer extends asr_base_scb_transformer #(nr_l2dl_fifo_trans, asr_base_scb_item);
    `uvm_component_utils(nr_l2dl_dtc_rdma_scb_transformer)

    function new (string name = "nr_l2dl_dtc_rdma_scb_transformer", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //transaction -> scb item
    extern virtual function void T2SCBT(nr_l2dl_fifo_trans in_pkt, output asr_base_scb_item scb_item[]);
endclass: nr_l2dl_dtc_rdma_scb_transformer

function void nr_l2dl_dtc_rdma_scb_transformer::T2SCBT(nr_l2dl_fifo_trans in_pkt, output asr_base_scb_item scb_item[]);
    //TODO: transform nr_l2dl_fifo_trans -> asr_base_scb_item 
    //scb_item: stream_id, addr, data, rw_type
    //scb_item=new[1];
    //scb_item[0]=new("scb_item");
    //scb_item[0].addr=in_pkt.addr;
    //scb_item[0].rw_type = asr_base_scb_item::READ; 
    //scb_item[0].data = in_pkt.rdata; 
endfunction


