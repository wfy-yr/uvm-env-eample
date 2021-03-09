class nr_l2dl_pld_pkt extends uvm_object;

    rand bit [7:0] pl_dat_stream[];

    
    `uvm_object_utils_begin(nr_l2dl_pld_pkt)
    `uvm_object_utils_end

    function new (string name = "nr_l2dl_pld_pkt");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH)
    endfunction : new

    constraint psize {
        pl_dat_stream.size() > 10000;
        pl_dat_stream.size() < 20000;
    }


    virtual task pack_hdr (int pld_size, ref bit [7:0] byte_q[$]);
        for(int i =0; i < pld_size; i++) begin
            byte_q.push_back(pl_dat_stream[i]);
        end
    endtask : pack_hdr
endclass
