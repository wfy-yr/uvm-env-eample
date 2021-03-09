class asr_base_scb_printer extends uvm_table_printer;
    static asr_base_scb_printer me;
    asr_base_scb_comparer       m_comparer;
    uvm_printer_row_info    objs_info[$][$];

    protected int m_max_name;
    protected int m_max_type;
    protected int m_max_size;
    protected int m_max_value;

    extern function new();
    extern static function asr_base_scb_printer get();
    extern function void calculate_max_widths();
    extern virtual function string emit();
    extern virtual function string obj_info_construct(uvm_object insert_obj, uvm_object expect_obj);
    extern virtual function string obj_sprint(uvm_object insert_obj, uvm_object expect_obj);
    extern virtual function void obj_print(uvm_object insert_obj, uvm_object expect_obj);

endclass

function asr_base_scb_printer::new();
    super.new();
    knobs.size=0;
    knobs.type_name=0;
    m_comparer=asr_base_scb_comparer::get();
endfunction

function asr_base_scb_printer asr_base_scb_printer::get();
    if(me==null) me=new();
    return me;
endfunction

function void asr_base_scb_printer::calculate_max_widths();
    m_max_name=8;
    m_max_type=4;
    m_max_size=4;  
    m_max_value=13; 
    foreach(m_rows[j]) begin
        int name_len;
        uvm_printer_row_info row = m_rows[j];
        if(j==0 & row.name=="<unnamed>") row.name=row.type_name;
        name_len = knobs.indent*row.level + row.name.len();
        if(name_len>m_max_name) m_max_name=name_len;
        if(row.type_name.len() > m_max_type) m_max_type=row.type_name.len();
        if(row.size.len() > m_max_size) m_max_size=row.size.len();
        if(row.val.len() > m_max_value) m_max_value=row.val.len();
    end
endfunction

function string asr_base_scb_printer::emit();
    objs_info.push_back(m_rows);
    m_rows.delete();
endfunction

function string asr_base_scb_printer::obj_info_construct(uvm_object insert_obj, uvm_object expect_obj);
    string s[$];
    string user_format;
    static string dash;
    static string space;
    string dashes;
    string emit;

    string linefeed = {"\n", knobs.prefix};

    m_rows.delete();
    objs_info.delete();
    void'(insert_obj.sprint(this));
    void'(expect_obj.sprint(this));

    insert_obj.__m_uvm_status_container.printer = this;
    insert_obj.__m_uvm_field_automation(null, UVM_PRINT, "");
    m_rows.push_front(objs_info[0][0]);
    calculate_max_widths();

    begin
        int q[5];
        int m;
        int qq[$];

        q = '{m_max_name,m_max_type,m_max_size,m_max_value,100};
        qq = q.max;
        m = qq[0];
        if(dash.len()<m) begin
            dash = {m{"-"}};
            space = {m{" "}};
        end
    end

    //table header string
    if(knobs.header) begin
        string header;
        user_format = format_header();
        if(user_format == "") begin
            string dash_id, dash_typ, dash_sz;
            dashes={dashes, "-"};
            header={header, "|"};
            if(knobs.identifier) begin
                dashes={dashes, dash.substr(1,m_max_name+2)};
                header={header, "Name", space.substr(1,m_max_name-2)};
            end
            if(knobs.type_name) begin
                dashes={dashes, dash.substr(1,m_max_type+2)};
                header={header, "Type", space.substr(1,m_max_type-2)};
            end
            if(knobs.size) begin
                dashes={dashes, dash.substr(1,m_max_size+2)};
                header={header, "Size", space.substr(1,m_max_size-2)};
            end
            dashes={dashes, dash.substr(1,m_max_value+1)};
            header={header, "Value(Insert)", space.substr(1,m_max_value-12)};
            dashes={dashes, "--"};
            header={header, "| "};

            dashes={dashes, dash.substr(1,m_max_value+1)};
            header={header, "Value(Expect)", space.substr(1,m_max_value-12)};
            dashes={dashes, "--"};
            header={header, "| "};

            dashes={dashes, dash.substr(1,7)};
            header={header, "Result", space.substr(1,1)};
            dashes={dashes, "-", linefeed};
            header={header, "|", linefeed};

            s.push_back({dashes, header, dashes});
        end
        else begin
            s.push_back({user_format, linefeed});
        end
    end

    //---------------Insert Time Extract -----------
    foreach(objs_info[0][i]) begin
        uvm_printer_row_info row_i = objs_info[0][i];
        uvm_printer_row_info row_e = objs_info[1][i];
        if(row_i.name=="end_time") begin
            s={s, "|"};
            s.push_back({"SCB_Time", space.substr(1, m_max_name-6)});
            s.push_back({row_i.val, space.substr(1, m_max_value-row_i.val.len()+1)});
            s={s, "| "};
            s.push_back({row_e.val, space.substr(1, m_max_value-row_e.val.len()+1)});
            s={s, "|"};
            s.push_back(space.substr(1, 7));
            s={s, " |", linefeed};
            s.push_back(dashes);
        end
    end

    foreach(m_rows[i]) begin
        uvm_printer_row_info row_i = objs_info[0][i];
        uvm_printer_row_info row_e = objs_info[1][i];
        if(user_format == "") begin
            string row_str;
            s={s, "|"};
            if(knobs.identifier) begin
                if(i==0 & row_i.name=="<unnamed>") row_i.name=row_i.type_name;
                row_str = {space.substr(1,row_i.level * knobs.indent), row_i.name,
                           space.substr(1,m_max_name-row_i.name.len()-(row_i.level * knobs.indent)+2)};
            end
            if(knobs.type_name) 
                row_str = {row_str, row_i.type_name, space.substr(1,m_max_type-row_i.type_name.len()+2)};

            if(knobs.size) 
                row_str = {row_str, row_i.size, space.substr(1,m_max_size-row_i.size.len()+2)};

            s.push_back({row_str, row_i.val, space.substr(1,m_max_value-row_i.val.len()+1)});
            s={s, "| "};
            s.push_back({row_e.val, space.substr(1, m_max_value-row_e.val.len()+1)});
            s={s, "|"};

            if(m_comparer.err_arg.size>0) begin
                if(row_i.name==m_comparer.err_arg[0]) begin
                    if(row_i.val != row_e.val) s.push_back({" NOMTH", space.substr(1,1)});
                    else s.push_back(space.substr(1,7));
                    s={s, " |", linefeed};
                    m_comparer.err_arg.delete(0);
                end else if(row_i.val !=row_e.val & row_e.val[0] !="@") begin
                    s.push_back(" NOCMP");
                    s={s, " |", linefeed};
                end else begin
                    s.push_back(space.substr(1,7));
                    s={s, " |", linefeed};
                end
            end else begin
                s.push_back(space.substr(1,7));
                s={s, " |", linefeed};
            end
        end
        else 
            s.push_back({user_format, linefeed});
    end

    if(knobs.footer) begin
        user_format = format_footer();
        if(user_format == "")
            s.push_back(dashes);
        else
            s.push_back({user_format, linefeed});
    end

    begin
        string q = {>>{s}};
        emit = q;
    end

    objs_info.delete();
    return emit;
endfunction

function string asr_base_scb_printer::obj_sprint(uvm_object insert_obj, uvm_object expect_obj);
    return {"\n", obj_info_construct(insert_obj, expect_obj)};
endfunction

function void asr_base_scb_printer::obj_print(uvm_object insert_obj, uvm_object expect_obj);
    `uvm_info("Scb Insert and Expect Infomation", $sformatf("%s", {"\n", obj_info_construct(insert_obj, expect_obj)}), UVM_NONE)
endfunction
