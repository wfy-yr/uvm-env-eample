`uvm_analysis_imp_decl(_insert)
`uvm_analysis_imp_decl(_expect)

class asr_base_scoreboard
    #( type T = int,
       type insert_type = T ,
       type expect_type = T ,
       type convert = uvm_class_converter #(T))
    extends uvm_scoreboard;

    typedef asr_base_scoreboard #(T,insert_type,expect_type,convert) this_type;
    `uvm_component_param_utils(this_type)

    typedef enum {UN_DIR    = 1, BI_DIR     = 0} scb_direction;
    typedef enum {IN_ORDER  = 1, OUT_ORDER  = 0} scb_order;
    typedef enum {EXACT_CHK = 1, LOSS_CHK   = 0} scb_chk;


    bit orphaned_check_en =  1;
    bit no_activity_check =  1;
    int expect_match_num  = -1;
    int unsigned expect_stream_match_num[int];
    int loss_max_num = 5;

    local bit scb_disable_en = 0; //only for register test

    //set stream name by user instead of stream id displayed in scoreboard report
    string stream_name[int];

    uvm_analysis_imp_insert #(insert_type, this_type) insert_export;
    uvm_analysis_imp_expect #(expect_type, this_type) expect_export;
    T                                                 pkts_buffer1[int][$];
    T                                                 pkts_buffer2[int][$];
    bit                                               stream_id_q[int];
    bit                                               scb_insert_dis[int];
    bit                                               scb_expect_dis[int];
    int                                               loss_num[int];
    scb_order                                         m_scb_order;
    scb_direction                                     m_scb_direction;
    scb_chk                                           m_scb_chk;
    int                                               n_inserted[int];
    int                                               n_inserted_dropped[int];
    int                                               n_expected[int];
    int                                               n_expected_dropped[int];
    int                                               n_matched[int];
    int                                               n_mismatched[int];
    int                                               n_dropped[int];
    int                                               n_not_found[int];
    int                                               n_orphaned[int];
    int                                               n_orphaned_ins[int];
    int                                               n_orphaned_exp[int];
    int                                               n_error_cnt;

    asr_base_scb_comparer         m_comparer;
    asr_base_scb_printer          m_printer;


    extern function new(string name="asr_base_scoreboard", uvm_component parent=null);
    extern virtual function void connect_phase(uvm_phase phase);

    extern virtual function void set_scb_property(scb_direction  m_scb_direction = UN_DIR,
                                                  scb_order      m_scb_order = IN_ORDER,
                                                  scb_chk        m_scb_chk = EXACT_CHK);

    extern virtual function void set_stream_name(int id, string name);

    extern virtual function string get_stream_name(int id);


    extern virtual function void set_orphaned_check_en(bit orphaned_check_en = 1);

    extern virtual function void chk_scb_property();
    extern virtual function void write_insert(insert_type insert_pkt);
    extern virtual function void write_expect(expect_type expect_pkt);

    extern virtual function void un_dir_check_pkts(T expect_pkts, int stream_id=0);
    extern virtual function void bi_dir_check_pkts(T expect_pkts, int stream_id=0, bit direction=0);


    extern virtual function void insert_transform(input insert_type insert_pkt,
                                                  output T          out_pkts[],
                                                  ref    bit        drop_bit,
                                                  ref    int        stream_id);

    extern virtual function void expect_transform(input expect_type expect_pkt,
                                                  output T          out_pkts[],
                                                  ref    bit        drop_bit,
                                                  ref    int        stream_id);
    //default : stream_id: -1 disable all sb_item queue.
    extern virtual function void disable_scb       (int stream_id=-1);
    extern virtual function void disable_scb_insert(int stream_id=-1);
    extern virtual function void disable_scb_expect(int stream_id=-1);
    extern virtual function void enable_scb        (int stream_id=-1);
    extern virtual function void enable_scb_insert (int stream_id=-1);
    extern virtual function void enable_scb_expect (int stream_id=-1);
    extern virtual function void flush_scb         (int stream_id=-1);
    
    extern virtual function void set_reg_test_dis ();
    extern virtual function void set_scb_disable ();
    extern virtual function void set_scb_enable ();
    extern virtual function void scb_report();
    extern virtual function int  scb_report_error_num();
    extern virtual function void report_phase(uvm_phase phase);

    extern virtual function int unsigned get_dec_size(int unsigned val);

endclass : asr_base_scoreboard

function asr_base_scoreboard::new(string name="asr_base_scoreboard", uvm_component parent=null);
    super.new(name, parent);
    insert_export = new("insert_export", this);
    expect_export = new("expect_export", this);
    
    m_scb_direction     = UN_DIR;
    m_scb_order         = IN_ORDER;
    m_scb_chk           = EXACT_CHK;

    m_printer = asr_base_scb_printer::get();
    m_comparer = asr_base_scb_comparer::get();
    n_error_cnt = 0;
endfunction : new

function void asr_base_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(uvm_config_db#(bit)::get(this, "", "orphaned_check_en", orphaned_check_en)) begin
        `uvm_info("BASE_SCB", $sformatf("%s get cfg: orphaned_check_en=%0d", this.get_name(), orphaned_check_en), UVM_MEDIUM)
    end

    if(uvm_config_db#(bit)::get(this, "", "scb_disable_en", scb_disable_en)) begin
        `uvm_info("BASE_SCB", $sformatf("%s get cfg: scb_disable_en=%0d", this.get_name(), scb_disable_en), UVM_MEDIUM)
    end

    if(uvm_config_db#(int)::get(this, "", "loss_max_num", loss_max_num)) begin
        `uvm_info("BASE_SCB", $sformatf("%s get cfg: loss_max_num=%0d", this.get_name(), loss_max_num), UVM_MEDIUM)
    end

    if(uvm_config_db#(int)::get(this, "", "expect_match_num", expect_match_num)) begin
        `uvm_info("BASE_SCB", $sformatf("%s get cfg: expect_match_num=%0d", this.get_name(), expect_match_num), UVM_MEDIUM)
    end

    if(uvm_config_db#(bit)::get(this, "", "no_activity_check", no_activity_check)) begin
        `uvm_info("BASE_SCB", $sformatf("%s get cfg: no_activity_check=%0d", this.get_name(), no_activity_check), UVM_MEDIUM)
    end
endfunction : connect_phase

function void asr_base_scoreboard::set_scb_property(scb_direction m_scb_direction = UN_DIR,
                                                scb_order     m_scb_order = IN_ORDER,
                                                scb_chk       m_scb_chk  = EXACT_CHK);
    this.m_scb_order = m_scb_order;
    this.m_scb_direction = m_scb_direction;
    this.m_scb_chk = m_scb_chk;
endfunction: set_scb_property

function void asr_base_scoreboard::set_stream_name(int id, string name);
    stream_name[id]=name;
endfunction: set_stream_name

function string asr_base_scoreboard::get_stream_name(int id);
    if(stream_name.exists(id)) return stream_name[id];
    else return $sformatf("stream%0d", id);
endfunction: get_stream_name

function void asr_base_scoreboard::set_orphaned_check_en(bit orphaned_check_en = 1);
    this.orphaned_check_en = orphaned_check_en;
endfunction: set_orphaned_check_en

function void asr_base_scoreboard::chk_scb_property();
    if((m_scb_order == OUT_ORDER) && (m_scb_chk == LOSS_CHK))begin
        `uvm_fatal("BASE_SCB", $sformatf("%s Don't support %s %s %s", this.get_name(), m_scb_order.name, m_scb_direction.name, m_scb_chk.name))
    end
endfunction: chk_scb_property

function void asr_base_scoreboard::write_insert(insert_type insert_pkt);
    T  out_pkts[];
    T  expect_pkts;
    bit drop_bit = 0;
    bit pkt_has_matched = 0;
    int stream_id = 0;
    insert_transform(insert_pkt, out_pkts, drop_bit, stream_id);

    if(scb_insert_dis[-1]|scb_insert_dis[stream_id]) return;
    foreach(out_pkts[i]) void'(out_pkts[i].end_tr($time));
    if(scb_disable_en) drop_bit=1;
    if(!drop_bit)begin
        stream_id_q[stream_id]=1;
        n_inserted[stream_id]+=out_pkts.size();
        case(m_scb_direction)
        UN_DIR : begin
                     foreach(out_pkts[i]) begin
                         pkt_has_matched = 0;
                         expect_pkts = out_pkts[i];
                         if(pkts_buffer2[stream_id].size()!=0)begin
                             int   match_idx;
                             foreach(pkts_buffer2[stream_id][j])begin
                                 if(expect_pkts.compare(pkts_buffer2[stream_id][j],m_comparer)) begin
                                     time insert_time, expect_time;
                                     insert_time = expect_pkts.get_end_time();
                                     expect_time = pkts_buffer2[stream_id][j].get_end_time();
                                     if(insert_time <= expect_time)begin
                                         `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare OK: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),m_printer.obj_sprint(expect_pkts,pkts_buffer2[stream_id][j])), UVM_HIGH)
                                         n_matched[stream_id]++;
                                     end
                                     else begin
                                         `uvm_fatal("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare MsMtch: Insert time[%0tns] later than Expect time[%0tns], Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),insert_time,expect_time,m_printer.obj_sprint(expect_pkts,pkts_buffer2[stream_id][j])))
                                         n_mismatched[stream_id]++;
                                         n_error_cnt++;
                                     end
                                     pkt_has_matched = 1;
                                     match_idx = j;
                                     break;
                                 end
                             end
                             if(pkt_has_matched)begin
                                 T     pkts_buffer_que_tmp[$];
                                 pkts_buffer_que_tmp = pkts_buffer2[stream_id];
                                 pkts_buffer_que_tmp.delete(match_idx);
                                 pkts_buffer2[stream_id] = pkts_buffer_que_tmp;
                             end
                         end
                         if(!pkt_has_matched)begin
                             pkts_buffer1[stream_id].push_back(expect_pkts);
                         end
                     end
                 end
        BI_DIR : begin
                     foreach(out_pkts[i]) begin bi_dir_check_pkts(out_pkts[i], stream_id, 0); end
                 end
        endcase
    end
    else begin
        n_inserted_dropped[stream_id]+=out_pkts.size();
    end
endfunction: write_insert

function void asr_base_scoreboard::write_expect(expect_type expect_pkt);
    T  out_pkts[];
    expect_type abc;
    bit drop_bit = 0;
    int stream_id = 0;
    expect_transform(expect_pkt, out_pkts, drop_bit, stream_id);

    if(scb_expect_dis[-1]|scb_expect_dis[stream_id]) return;
    foreach(out_pkts[i]) void'(out_pkts[i].end_tr($time));
    if(scb_disable_en) drop_bit=1;
    if(!drop_bit)begin
        stream_id_q[stream_id]=1;
        n_expected[stream_id]+=out_pkts.size();
        case(m_scb_direction)
        UN_DIR : begin
                     foreach(out_pkts[i]) begin un_dir_check_pkts(out_pkts[i], stream_id); end
                 end
        BI_DIR : begin
                     foreach(out_pkts[i]) begin bi_dir_check_pkts(out_pkts[i], stream_id, 1); end
                 end
        endcase
    end
    else begin
        n_expected_dropped[stream_id]+=out_pkts.size();
    end
endfunction: write_expect

function void asr_base_scoreboard::un_dir_check_pkts(input T expect_pkts, int stream_id=0);
    bit pkt_has_matched = 0;
    string s;
    int match_idx;

    if(pkts_buffer1[stream_id].size() == 0)begin
        pkts_buffer2[stream_id].push_back(expect_pkts);
        return;
    end

    if((m_scb_order == IN_ORDER) && (m_scb_chk == EXACT_CHK))begin
        if(!expect_pkts.compare(pkts_buffer1[stream_id][0],m_comparer)) begin
            n_mismatched[stream_id]++; 
            `uvm_error("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare MsMtch: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),m_printer.obj_sprint(pkts_buffer1[stream_id][0],expect_pkts)))
            void'(pkts_buffer1[stream_id].pop_front());
            n_error_cnt++;
        end else begin
            n_matched[stream_id]++;
            `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare OK: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),m_printer.obj_sprint(pkts_buffer1[stream_id][0],expect_pkts)), UVM_HIGH)
            void'(pkts_buffer1[stream_id].pop_front());
        end
    end

    if((m_scb_order == IN_ORDER) && (m_scb_chk == LOSS_CHK))begin
        pkt_has_matched = 0;
        foreach(pkts_buffer1[stream_id][i])begin
            if(!expect_pkts.compare(pkts_buffer1[stream_id][i],m_comparer)) begin
                `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) drop pkts[%s][%0d] info. \n%s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),i,m_printer.obj_sprint(pkts_buffer1[stream_id][i],expect_pkts)), UVM_HIGH)
                n_dropped[stream_id]++;
                loss_num[stream_id]++;
            end else begin
                `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare OK: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),m_printer.obj_sprint(pkts_buffer1[stream_id][i],expect_pkts)), UVM_HIGH)
                n_matched[stream_id]++;
                pkt_has_matched = 1;
                match_idx = i;
                loss_num[stream_id]=0;
                break;
            end
        end
        if(!pkt_has_matched)begin
            n_mismatched[stream_id]++;
            `uvm_error("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Insert pkts[%0d] Not Found, Expect pkt info. \n%s", this.get_name(), m_scb_direction.name,get_stream_name(stream_id),m_scb_order.name,m_scb_chk.name,stream_id,expect_pkts.sprint()))
            n_error_cnt++;
        end
        else begin
            repeat (match_idx+1) void'(pkts_buffer1[stream_id].pop_front());
        end

        if(loss_max_num > 0 && loss_num[stream_id]>loss_max_num) begin
            `uvm_error("BASE_SCB", $sformatf("%s(%s/%s/%s) loss_num[%s]=%0d is bigger than the max number %0d", this.get_name(), m_scb_direction.name,m_scb_order.name,m_scb_chk.name,get_stream_name(stream_id),loss_num[stream_id],loss_max_num))
            n_error_cnt++;
        end
        if(pkt_has_matched) loss_num[stream_id]=0;
    end

    if((m_scb_order == OUT_ORDER) && (m_scb_chk == EXACT_CHK))begin
        pkt_has_matched = 0;
        foreach(pkts_buffer1[stream_id][i])begin
            if(expect_pkts.compare(pkts_buffer1[stream_id][i],m_comparer)) begin
                `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare OK: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),m_printer.obj_sprint(pkts_buffer1[stream_id][i],expect_pkts)),UVM_HIGH)
                n_matched[stream_id]++; 
                pkt_has_matched = 1;
                match_idx = i;
                break;
            end
        end
        if(!pkt_has_matched)begin
            n_mismatched[stream_id]++; 
            `uvm_error("BASE_SCB", $sformatf("%s(%s/%s/%s) Insert pkts[%s] Not Found, Expect pkt info. \n%s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),expect_pkts.sprint()))
            n_error_cnt++;
        end
        else begin
            pkts_buffer1[stream_id].delete(match_idx);
        end
    end
endfunction: un_dir_check_pkts

function void asr_base_scoreboard::bi_dir_check_pkts(input T expect_pkts, int stream_id=0, bit direction=0);
    T   tmp_pkts[$];
    bit pkt_has_matched = 0;
    string s;
    int match_idx;

    case(direction)
        0: tmp_pkts=pkts_buffer2[stream_id];
        1: tmp_pkts=pkts_buffer1[stream_id];
    endcase

    if(tmp_pkts.size() == 0)begin
        case(direction)
            0: pkts_buffer1[stream_id].push_back(expect_pkts);
            1: pkts_buffer2[stream_id].push_back(expect_pkts);
        endcase
        return;
    end

    if((m_scb_order == IN_ORDER) && (m_scb_chk == EXACT_CHK))begin
        if(!expect_pkts.compare(tmp_pkts[0],m_comparer)) begin
            n_mismatched[stream_id]++; 
            `uvm_error("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s][%0d]Compare MsMtch: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),n_matched[stream_id]+n_mismatched[stream_id],m_printer.obj_sprint(direction ? tmp_pkts[0] : expect_pkts, direction ? expect_pkts : tmp_pkts[0])))
            n_error_cnt++;
        end else begin
            n_matched[stream_id]++;
            `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s][%0d]Compare OK: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id), n_matched[stream_id]+n_mismatched[stream_id],m_printer.obj_sprint(direction ? tmp_pkts[0] : expect_pkts, direction ? expect_pkts : tmp_pkts[0])), UVM_HIGH)
        end
        case(direction)
            0: void'(pkts_buffer2[stream_id].pop_front());
            1: void'(pkts_buffer1[stream_id].pop_front());
        endcase
    end

    if((m_scb_order == IN_ORDER) && (m_scb_chk == LOSS_CHK))begin
        pkt_has_matched = 0;
        foreach(tmp_pkts[i])begin
            if(!expect_pkts.compare(tmp_pkts[i],m_comparer)) begin
                `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) drop %s pkts[%s][%0d] info. \n%s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name, direction ? "Expect" : "Insert",get_stream_name(stream_id),i,tmp_pkts[i].sprint()), UVM_HIGH)
                n_dropped[stream_id]++;
                loss_num[stream_id]++;
            end else begin
                `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare OK: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,get_stream_name(stream_id),m_printer.obj_sprint(direction ? tmp_pkts[0] : expect_pkts, direction ? expect_pkts : tmp_pkts[0])), UVM_HIGH)
                n_matched[stream_id]++;
                pkt_has_matched = 1;
                match_idx = i;
                break;
            end
        end
        if(!pkt_has_matched)begin
            `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) %s pkts[%s] pkt was not found, %s pkt info. \n%s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name, direction ? "Expect" : "Insert",get_stream_name(stream_id), direction ? "Expect" : "Insert",expect_pkts.sprint()), UVM_HIGH)
            case(direction)
                0: begin
                       pkts_buffer2[stream_id].delete();
                       pkts_buffer1[stream_id].push_back(expect_pkts);
                   end
                1: begin
                       pkts_buffer1[stream_id].delete();
                       pkts_buffer2[stream_id].push_back(expect_pkts);
                   end
            endcase
        end
        else begin
            case(direction)
                0: repeat (match_idx+1) void'(pkts_buffer2[stream_id].pop_front());
                1: repeat (match_idx+1) void'(pkts_buffer1[stream_id].pop_front());
            endcase
        end

        if(loss_max_num > 0 && loss_num[stream_id]>loss_max_num) begin
            `uvm_error("BASE_SCB", $sformatf("%s(%s/%s/%s) loss_num[%s]=%0d is bigger than the max number %0d", this.get_name(), m_scb_direction.name,m_scb_order.name,m_scb_chk.name,get_stream_name(stream_id),loss_num[stream_id],loss_max_num))
            n_error_cnt++;
        end
        if(pkt_has_matched) loss_num[stream_id]=0;
    end

    if((m_scb_order == OUT_ORDER) && (m_scb_chk == EXACT_CHK))begin
        foreach(tmp_pkts[i])begin
            if(expect_pkts.compare(tmp_pkts[i],m_comparer)) begin
                `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) [%s]Compare OK: Insert and Expect info. %s", this.get_name(), m_scb_direction.name, m_scb_order.name,get_stream_name(stream_id), m_scb_chk.name,m_printer.obj_sprint(direction ? tmp_pkts[i] : expect_pkts, direction ? expect_pkts : tmp_pkts[i])),UVM_HIGH)
                n_matched[stream_id]++; 
                pkt_has_matched = 1;
                match_idx = i;
                break;
            end
        end
        if(!pkt_has_matched)begin
            `uvm_info("BASE_SCB", $sformatf("%s(%s/%s/%s) %s pkts[%s] pkt was not found, %s pkt info. \n%s", this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name, direction ? "Insert" : "Expect",get_stream_name(stream_id), direction ? "Expect" : "Insert",expect_pkts.sprint()), UVM_HIGH)
            case(direction)
                0: begin
                       pkts_buffer1[stream_id].push_back(expect_pkts);
                   end
                1: begin
                       pkts_buffer2[stream_id].push_back(expect_pkts);
                   end
            endcase
        end
        else begin
            case(direction)
                0: begin
                       pkts_buffer2[stream_id].delete(match_idx);
                   end
                1: begin
                       pkts_buffer1[stream_id].delete(match_idx);
                   end
            endcase
        end
    end
endfunction: bi_dir_check_pkts

function void asr_base_scoreboard::insert_transform(input insert_type insert_pkt,
                                                output T          out_pkts[],
                                                ref    bit        drop_bit,
                                                ref    int        stream_id);
    out_pkts   = new[1];
    if(!$cast(out_pkts[0], insert_pkt)) out_pkts.delete();
    drop_bit = 0;
endfunction : insert_transform

function void asr_base_scoreboard::expect_transform(input expect_type expect_pkt,
                                                output T          out_pkts[],
                                                ref    bit        drop_bit,
                                                ref    int        stream_id);
    out_pkts   = new[1];
    if(!$cast(out_pkts[0], expect_pkt)) out_pkts.delete();
    drop_bit = 0;
endfunction : expect_transform

function void asr_base_scoreboard::disable_scb(int stream_id=-1);
    disable_scb_insert(stream_id);
    disable_scb_expect(stream_id);
endfunction : disable_scb

function void asr_base_scoreboard::disable_scb_insert(int stream_id=-1);
    scb_insert_dis[stream_id]=1;
endfunction : disable_scb_insert

function void asr_base_scoreboard::disable_scb_expect(int stream_id=-1);
    scb_expect_dis[stream_id]=1;
endfunction : disable_scb_expect

function void asr_base_scoreboard::enable_scb(int stream_id=-1);
    enable_scb_insert(stream_id);
    enable_scb_expect(stream_id);
endfunction : enable_scb

function void asr_base_scoreboard::enable_scb_insert(int stream_id=-1);
    scb_insert_dis[stream_id]=0;
endfunction : enable_scb_insert

function void asr_base_scoreboard::enable_scb_expect(int stream_id=-1);
    scb_expect_dis[stream_id]=0;
endfunction : enable_scb_expect

function void asr_base_scoreboard::flush_scb(int stream_id=-1);
    if(stream_id==-1)begin
        foreach(pkts_buffer1[i]) pkts_buffer1[i].delete();
        foreach(pkts_buffer2[i]) pkts_buffer2[i].delete();
    end else begin
        pkts_buffer1[stream_id].delete();
        pkts_buffer2[stream_id].delete();
    end
endfunction : flush_scb

function void asr_base_scoreboard::scb_report();
    int   tb_name_len=12;
    int   s_len = 0;
    string s = this.get_name();
    int   tbl_len[string];
    int   blk_len1[string];
    int   blk_len2[string];
    string delimeter;
    string tbl_hdr;
    string tbl_format;
    int   stream_hdr_len = 0;
    string tmp;

    //match num chk
    if(expect_match_num >=0 && n_matched.sum != expect_match_num) begin
        `uvm_error("BASE_SCB", $sformatf("%s matched num not as expected; Expect %0d, Actual %0d", this.get_name(), expect_match_num, n_matched.sum))
    end
    foreach(expect_stream_match_num[ii])begin
        if(expect_stream_match_num[ii] == 0 && n_matched.exists(ii))begin
            `uvm_error("BASE_SCB", $sformatf("%s [%s]matched num not as expected; Expect %0d, Actual %0d", this.get_name(), get_stream_name(ii), 0, n_matched[ii]))
        end
        else if(expect_stream_match_num[ii] != 0 && n_matched.exists(ii))begin
            `uvm_error("BASE_SCB", $sformatf("%s [%s]matched num not as expected; Expect %0d, Actual %0d", this.get_name(), get_stream_name(ii), expect_stream_match_num[ii],0))
        end
        else if(expect_stream_match_num[ii] != n_matched[ii])begin
            `uvm_error("BASE_SCB", $sformatf("%s [%s]matched num not as expected; Expect %0d, Actual %0d", this.get_name(), get_stream_name(ii), expect_stream_match_num[ii], n_matched[ii]))
        end
    end
    //no activity check
    if(no_activity_check && (n_inserted.sum() + n_inserted_dropped.sum() + n_expected.sum() + n_expected_dropped.sum() == 0))begin
        `uvm_error("BASE_SCB", $sformatf("%s has no activity", this.get_name()))
    end

    tbl_len["InstOK"] = 4;
    tbl_len["InsDrp"] = 4;
    tbl_len["ExptOK"] = 4;
    tbl_len["ExpDrp"] = 4;
    tbl_len["Matchd"] = 4;
    tbl_len["MsMtch"] = 4;
    tbl_len["Dorppd"] = 4;
    tbl_len["NotFnd"] = 4;
    tbl_len["OrpIns"] = 4;
    tbl_len["OrpExp"] = 4;

    //orphaned chk
    foreach(stream_id_q[i]) begin
        int sid = i;
        string str;
        str = get_stream_name(sid);
        
        n_orphaned[i]=this.pkts_buffer1[i].size()+this.pkts_buffer2[i].size();
        n_orphaned_ins[i]=this.pkts_buffer1[i].size();
        n_orphaned_exp[i]=this.pkts_buffer2[i].size();

        if(n_orphaned[i]>0 & m_scb_chk==EXACT_CHK & orphaned_check_en) begin
            `uvm_error(this.get_name(), $sformatf("%s(%s/%s/%s) pkts has data unchecked : insert_pkts[%s]=%0d, expect_pkts[%s]=%0d",this.get_name(), m_scb_direction.name, m_scb_order.name, m_scb_chk.name,str,pkts_buffer1[i].size(),str,pkts_buffer2[i].size()))
            foreach(pkts_buffer1[i][idx])begin
                `uvm_error("BASE_SCB", $sformatf("insert_pkts[%s][%0d] has data unchecked : \n %s", str, idx, pkts_buffer1[i][idx].sprint()))
            end
            foreach(pkts_buffer2[i][idx])begin
                `uvm_error("BASE_SCB", $sformatf("expect_pkts[%s][%0d] has data unchecked : \n %s", str, idx, pkts_buffer2[i][idx].sprint()))
            end
            n_error_cnt++;
        end
        if(m_scb_chk == LOSS_CHK & loss_max_num > 0 & (n_orphaned[i]+loss_num[i]>loss_max_num)) begin
            `uvm_error("BASE_SCB", $sformatf("%s(%s/%s/%s) loss_num[%s]=%0d is bigger than the max number %0d", this.get_name(), m_scb_direction.name,m_scb_order.name,m_scb_chk.name,str,n_orphaned[i]+loss_num[i],loss_max_num))
            n_error_cnt++;
        end
    end
    foreach(stream_id_q[i]) begin
        int stream_id=i;
        tmp = get_stream_name(stream_id);
        if(tmp.len() > tb_name_len) tb_name_len = tmp.len();
    end

    // s : table hdr
    s_len = s.len();
    if(s_len < tb_name_len) begin
        int blank_len = tb_name_len-s_len;
        s = {{(blank_len/2){" "}}, s, {(blank_len-blank_len/2){" "}}};
    end else if(s_len > tb_name_len) begin
        s = s.substr(0, s_len-1);
        tb_name_len=s_len;
    end

    begin
        int dec_size;

        dec_size = get_dec_size(n_inserted.sum);
        if(dec_size > tbl_len["InstOK"]) tbl_len["InstOK"] = dec_size;
        dec_size = get_dec_size(n_inserted_dropped.sum);
        if(dec_size > tbl_len["InsDrp"]) tbl_len["InsDrp"] = dec_size;
        dec_size = get_dec_size(n_expected.sum);
        if(dec_size > tbl_len["ExptOK"]) tbl_len["ExptOK"] = dec_size;
        dec_size = get_dec_size(n_expected_dropped.sum);
        if(dec_size > tbl_len["ExpDrp"]) tbl_len["ExpDrp"] = dec_size;
        dec_size = get_dec_size(n_matched.sum);
        if(dec_size > tbl_len["Matchd"]) tbl_len["Matchd"] = dec_size;
        dec_size = get_dec_size(n_mismatched.sum);
        if(dec_size > tbl_len["MsMtch"]) tbl_len["MsMtch"] = dec_size;
        dec_size = get_dec_size(n_dropped.sum);
        if(dec_size > tbl_len["Droppd"]) tbl_len["Droppd"] = dec_size;
        dec_size = get_dec_size(n_not_found.sum);
        if(dec_size > tbl_len["NotFnd"]) tbl_len["NotFnd"] = dec_size;
        dec_size = get_dec_size(n_orphaned_ins.sum);
        if(dec_size > tbl_len["OrpIns"]) tbl_len["OrpIns"] = dec_size;
        dec_size = get_dec_size(n_orphaned_exp.sum);
        if(dec_size > tbl_len["OrpExp"]) tbl_len["OrpExp"] = dec_size;
    end

    foreach(tbl_len[item]) begin
        blk_len1[item] = (tbl_len[item]+2-6)/2;
        blk_len2[item] = tbl_len[item]+2-6-blk_len1[item];
    end

    delimeter = $sformatf("+-%s-+-%s-+-%s-+-%s-+-%s-+-%s-+-%s-+-%s-+-%s-+-%s-+-%s-+",
             {tb_name_len{"-"}},
             {tbl_len["InstOK"]{"-"}},
             {tbl_len["InsDrp"]{"-"}},
             {tbl_len["ExptOK"]{"-"}},
             {tbl_len["ExpDrp"]{"-"}},
             {tbl_len["Matchd"]{"-"}},
             {tbl_len["MsMtch"]{"-"}},
             {tbl_len["Dorppd"]{"-"}},
             {tbl_len["NotFnd"]{"-"}},
             {tbl_len["OrpIns"]{"-"}},
             {tbl_len["OrpExp"]{"-"}}
    );
    tbl_hdr = $sformatf("| %s |%s%s%s|%s%s%s|%s%s%s|%s%s%s|%s%s%s|%s%s%s|%s%s%s|%s%s%s|%s%s%s|%s%s%s|",
             s,
             {blk_len1["InstOK"]{" "}}, "InstOK", {blk_len2["InstOK"]{" "}},
             {blk_len1["InsDrp"]{" "}}, "InsDrp", {blk_len2["InsDrp"]{" "}},
             {blk_len1["ExptOK"]{" "}}, "ExptOK", {blk_len2["ExptOK"]{" "}},
             {blk_len1["ExpDrp"]{" "}}, "ExpDrp", {blk_len2["ExpDrp"]{" "}},
             {blk_len1["Matchd"]{" "}}, "Matchd", {blk_len2["Matchd"]{" "}},
             {blk_len1["MsMtch"]{" "}}, "MsMtch", {blk_len2["MsMtch"]{" "}},
             {blk_len1["Dorppd"]{" "}}, "Dorppd", {blk_len2["Dorppd"]{" "}},
             {blk_len1["NotFnd"]{" "}}, "NotFnd", {blk_len2["NotFnd"]{" "}},
             {blk_len1["OrpIns"]{" "}}, "OrpIns", {blk_len2["OrpIns"]{" "}},
             {blk_len1["OrpExp"]{" "}}, "OrpExp", {blk_len2["OrpExp"]{" "}}
    );
    tbl_format = $sformatf("| %%s | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd |",
             tbl_len["InstOK"],
             tbl_len["InsDrp"],
             tbl_len["ExptOK"],
             tbl_len["ExpDrp"],
             tbl_len["Matchd"],
             tbl_len["MsMtch"],
             tbl_len["Dorppd"],
             tbl_len["NotFnd"],
             tbl_len["OrpIns"],
             tbl_len["OrpExp"]
    );
    $display("\nCurrent scoreboard type [ Direction:%s Order:%s Check:%s ]", m_scb_direction.name, m_scb_order.name, m_scb_chk.name);
    $display(delimeter);
    $display(tbl_hdr);
    $display(delimeter);

    foreach(stream_id_q[i]) begin
        int stream_id=i;
        s= get_stream_name(stream_id);
        s_len = s.len();
        if(s_len < tb_name_len) begin
            int blank_len = tb_name_len-s_len;
            s = {{(blank_len/2){" "}}, s, {(blank_len-blank_len/2){" "}}};
        end else if(s_len > tb_name_len) begin
            s = s.substr(0, tb_name_len-1);
        end

        $display($sformatf(tbl_format, s, 
               n_inserted[stream_id], n_inserted_dropped[stream_id],
               n_expected[stream_id], n_expected_dropped[stream_id],
               n_matched[stream_id],
               n_mismatched[stream_id], n_dropped[stream_id],
               n_not_found[stream_id], n_orphaned_ins[stream_id], n_orphaned_exp[stream_id]));
        $display(delimeter);
    end

    tbl_format = $sformatf("| %sTOTAL%s | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd | %%%0dd |",
             {((tb_name_len-5)/2){" "}},{((tb_name_len-5)-(tb_name_len-5)/2){" "}},
             tbl_len["InstOK"],
             tbl_len["InsDrp"],
             tbl_len["ExptOK"],
             tbl_len["ExpDrp"],
             tbl_len["Matchd"],
             tbl_len["MsMtch"],
             tbl_len["Dorppd"],
             tbl_len["NotFnd"],
             tbl_len["OrpIns"],
             tbl_len["OrpExp"]
    );
    $display($sformatf(tbl_format, 
           n_inserted.sum, n_inserted_dropped.sum,
           n_expected.sum, n_expected_dropped.sum,
           n_matched.sum,
           n_mismatched.sum, n_dropped.sum,
           n_not_found.sum, n_orphaned_ins.sum, n_orphaned_exp.sum));
    $display(delimeter);
endfunction : scb_report

function int asr_base_scoreboard::scb_report_error_num();
    scb_report_error_num = n_error_cnt;
endfunction : scb_report_error_num

function void asr_base_scoreboard::set_reg_test_dis();
    scb_disable_en = 1;
endfunction : set_reg_test_dis

function void asr_base_scoreboard::set_scb_disable();
    scb_disable_en = 1;
endfunction : set_scb_disable

function void asr_base_scoreboard::set_scb_enable();
    scb_disable_en = 0;
endfunction : set_scb_enable

function void asr_base_scoreboard::report_phase(uvm_phase phase);
    if(!scb_disable_en) scb_report();
endfunction : report_phase

function int unsigned asr_base_scoreboard::get_dec_size(int unsigned val);
    if(val == 0) return 0;
    else return $log10(val)+1;
endfunction : get_dec_size

