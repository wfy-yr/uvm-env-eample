// =========================================================================== //
// Author       : fengyangwu - ASR
// Last modified: 2020-07-09 15:14
// Filename     : hw_top.sv
// Description  : 
// =========================================================================== //
`ifndef HW_TOP_V
`define HW_TOP_V

module hw_top;

    wire          l2mac_re;
    wire  [13:0]  l2mac_raddr;
    wire  [11:0]  l2mac_tag;
    reg           l2mac_rvld;
    reg   [127:0] l2mac_rdata;
    reg   [127:0] mac_memory[0:204800];
    reg   [127:0] dtc_memory[0:204800];

    wire          l2dtc_re;
    wire  [13:0]  l2dtc_raddr;
    wire  [11:0]  l2dtc_tag;
    reg           l2dtc_rvld;
    reg   [127:0] l2dtc_rdata;

    reg           l2mac_rvld_temp0;
    reg           l2mac_rvld_temp1;
    reg           l2mac_rvld_temp2;
    reg           l2mac_rvld_temp3;

    reg           l2dtc_rvld_temp0;
    reg           l2dtc_rvld_temp1;
    reg           l2dtc_rvld_temp2;
    reg           l2dtc_rvld_temp3;

    reg   [127:0] rdata_l2mac0;
    reg   [127:0] rdata_l2mac1;
    reg   [127:0] rdata_l2mac2;
    reg   [127:0] rdata_l2mac3;

    reg   [127:0] rdata_l2dtc0;
    reg   [127:0] rdata_l2dtc1;
    reg   [127:0] rdata_l2dtc2;
    reg   [127:0] rdata_l2dtc3;


    always @ (posedge dut.clk983m or dut.clkgen_rstn) begin
        if (!dut.clkgen_rstn) begin
            rdata_l2mac0 <= 'hx;
        end
        else if (l2mac_re) begin
            if((dut.u_nr_rx_mac.cfg_byte_inv_en == 1'h1)&&(dut.u_nr_rx_mac.cfg_bit_inv_en == 1'h1))begin
                for(int ii=0; ii<128; ii++)begin
                    rdata_l2mac0[ii] <= mac_memory[l2mac_raddr][127-ii];
                end
            end else if(dut.u_nr_rx_mac.cfg_byte_inv_en == 1'h1)begin
                for(int ii=0; ii<16; ii++)begin
                    rdata_l2mac0[8*ii +: 8] <= mac_memory[l2mac_raddr][8*(15-ii) +: 8];
                end
            end else if(dut.u_nr_rx_mac.cfg_bit_inv_en == 1'h1)begin
                for(int ii=0; ii<16; ii++)begin
                    for(int jj=0; jj<8; jj++)begin
                        rdata_l2mac0[jj+8*ii] <= mac_memory[l2mac_raddr][7-jj+8*ii];
                    end
                end
            end else begin
                rdata_l2mac0 <= mac_memory[l2mac_raddr];
            end
        end
    end

    always @ (posedge dut.clk983m or dut.clkgen_rstn) begin
        if (!dut.clkgen_rstn) begin
            rdata_l2dtc0 <= 'hx;
        end
        else if ((l2dtc_re == 'h1)&&(((l2dtc_raddr[13:10] != l2mac_raddr[13:10])&&(l2mac_re == 'h1)) || (l2mac_re == 'h0) || (l2mac_tag[6:0] != l2dtc_tag[6:0]))) begin
            rdata_l2dtc0 <= dtc_memory[l2dtc_raddr];
        end
    end

    always @ (posedge dut.clk983m or dut.clkgen_rstn) begin
        if (!dut.clkgen_rstn) begin
            l2mac_rvld_temp0  <= 'h0;
            l2mac_rvld_temp1  <= 'h0;
            l2mac_rvld_temp2  <= 'h0;
            l2mac_rvld_temp3  <= 'h0;
            l2mac_rvld        <= 'h0;
        end
        else begin
            l2mac_rvld_temp0  <= l2mac_re;
            l2mac_rvld_temp1  <= l2mac_rvld_temp0;
            l2mac_rvld_temp2  <= l2mac_rvld_temp1;
            l2mac_rvld_temp3  <= l2mac_rvld_temp2;
            l2mac_rvld        <= l2mac_rvld_temp3;
        end
    end

    always @ (posedge dut.clk983m or dut.clkgen_rstn) begin
            if (!dut.clkgen_rstn) begin
                l2dtc_rvld_temp0  <= 'h0;
                l2dtc_rvld_temp1  <= 'h0;
                l2dtc_rvld_temp2  <= 'h0;
                l2dtc_rvld_temp3  <= 'h0;
                l2dtc_rvld        <= 'h0;
            end
            else begin
                l2dtc_rvld_temp0  <= (l2dtc_re == 'h1)&&(((l2dtc_raddr[13:10] != l2mac_raddr[13:10])&&(l2mac_re == 'h1)) || (l2mac_re == 'h0) || (l2mac_tag[6:0] != l2dtc_tag[6:0]));
                l2dtc_rvld_temp1  <= l2dtc_rvld_temp0;
                l2dtc_rvld_temp2  <= l2dtc_rvld_temp1;
                l2dtc_rvld_temp3  <= l2dtc_rvld_temp2;
                l2dtc_rvld        <= l2dtc_rvld_temp3;
            end
    end

    always @ (posedge dut.clk983m or dut.clkgen_rstn) begin
        if (!dut.clkgen_rstn) begin
            rdata_l2mac0 <= 'hx;
            rdata_l2mac1 <= 'hx;
            rdata_l2mac2 <= 'hx;
            rdata_l2mac3 <= 'hx;
            l2mac_rdata <= 'hx;
        end
        else begin
            rdata_l2mac1  <= rdata_l2mac0;
            rdata_l2mac2  <= rdata_l2mac1;
            rdata_l2mac3  <= rdata_l2mac2;
            l2mac_rdata  <= rdata_l2mac3;
        end
    end

    always @ (posedge dut.clk983m or dut.clkgen_rstn) begin
        if (!dut.clkgen_rstn) begin
            rdata_l2dtc0 <= 'hx;
            rdata_l2dtc1 <= 'hx;
            rdata_l2dtc2 <= 'hx;
            rdata_l2dtc3 <= 'hx;
            l2dtc_rdata <= 'hx;
        end
        else begin
            rdata_l2dtc1  <= rdata_l2dtc0;
            rdata_l2dtc2  <= rdata_l2dtc1;
            rdata_l2dtc3  <= rdata_l2dtc2;
            l2dtc_rdata  <= rdata_l2dtc3;
        end
    end

    nr_l2_downlink dut(
        .l2mac_re      (l2mac_re   ),
        .l2mac_tag     (l2mac_tag  ),
        .l2mac_raddr   (l2mac_raddr),
        .l2mac_rvld    (l2mac_rvld ),
        .l2mac_rdata   (l2mac_rdata),
        .l2dtc_re      (l2dtc_re   ),
        .l2dtc_tag     (l2dtc_tag  ),
        .l2dtc_raddr   (l2dtc_raddr),
        .l2dtc_rvld    (l2dtc_rvld ),
        .l2dtc_rdata   (l2dtc_rdata)
        );


    `NR_L2DL_L1_CFG_IF_RTL(nr_l2dl_l1_cfg_if, dut, 1);
    `NR_L2DL_L2_CFG_IF_RTL(nr_l2dl_l2_cfg_if, dut, 1);
    `NR_L2DL_TB_CMD_IF_RTL(nr_l2dl_tb_cmd_if, dut, 1);

    //------reuse  mac -------------------------------
    `NR_L2DL_TB_CMD_IF_RTL(rx_mac_tb_cmd_if, dut, 1);
    `RX_MAC_L1_MCE_IF_RTL(rx_mac_l1_mce_if, dut, 1);
    `RX_MAC_L2_MCE_IF_RTL(rx_mac_l2_mce_if, dut, 1);
    `RX_MAC_DL_NODE0_IF_RTL(rx_mac_dl_node0_if, dut, 1);
    `RX_MAC_DMA_IF_RTL(rx_mac_dma_if, dut, 1);
    `RX_MAC_DTC_CMD_IF_RTL(rx_mac_dtc_cmd_if, dut, 1);
    `RX_MAC_TOP_IF_RTL(rx_mac_top_if, dut, 1);
    //--------------------------------------------------------
    //`RX_MAC_DMA_IF_RTL(nr_l2dl_mac_dlnode0_dma_if, dut, 1);
    //`RX_MAC_DMA_IF_RTL(nr_l2dl_mac_l1mce_dma_if, dut, 1);
    //`RX_MAC_DMA_IF_RTL(nr_l2dl_mac_l2mce_dma_if, dut, 1);
    //`RX_MAC_DMA_IF_RTL(nr_l2dl_mac_l1tbinfo_dma_if, dut, 1);
    //`RX_MAC_DMA_IF_RTL(nr_l2dl_mac_l2tbinfo_dma_if, dut, 1);
    `DL_DTC_DMA_IF_RTL(nr_l2dl_dtc_dma_if, dut, 1);
    
    `NR_L2DL_DTC_PLD_IF_RTL(nr_l2dl_dtc_pld_if, dut, 1);
    `NR_L2DL_DTC_RDMA_IF_RTL(nr_l2dl_dtc_rdma_if, dut, 1);
    `NR_L2DL_TOP_IF_RTL(nr_l2dl_top_if, dut, 1);
endmodule

`endif

