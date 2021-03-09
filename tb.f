+define+UVM_PACKER_MAX_BYTES=1500000 
+define+UVM_DISABLE_AUTO_ITEM_RECORDING -timescale=1ns/1fs 
+define+SVT_UVM_TECHNOLOGY
+define+UVM_NO_DPI
//======================= common lib path ===============================
+incdir+/tools/Synopsys/verdi_vK-2015.09-SP2/etc/uvm-1.1/src
+incdir+/home/pingli/vip_2018/ahb/include/sverilog
+incdir+/home/pingli/vip_2018/apb/include/sverilog
+incdir+/home/pingli/vip_2018/ahb/src/sverilog/vcs
+incdir+/home/pingli/vip_2018/apb/src/sverilog/vcs
+incdir+/home/pingli/vip_2018/axi/include/sverilog
+incdir+/home/pingli/vip_2018/axi/src/sverilog/vcs

//uvm_pkg
/tools/Synopsys/verdi_vK-2015.09-SP2/etc/uvm-1.1/src/uvm.sv
///home/pingli/vip_2018/ahb/include/sverilog/svt_ahb.uvm.pkg
///home/pingli/vip_2018/apb/include/sverilog/svt_apb.uvm.pkg
///home/pingli/vip_2018/apb/include/sverilog/svt_apb_defines.svi
/home/pingli/vip_2018/axi/include/sverilog/svt_apb_if.svi
///home/pingli/vip_2018/apb/src/sverilog/vcs/svt_apb_system_configuration.sv
/home/pingli/vip_2018/axi/include/sverilog/svt_axi.uvm.pkg
/home/pingli/vip_2018/axi/include/sverilog/svt_axi_if.svi
/home/pingli/vip_2018/axi/include/sverilog/svt_axi_defines.svi
/home/pingli/vip_2018/axi/src/sverilog/vcs/svt_axi_system_configuration.sv
/home/pingli/vip_2018/axi/include/sverilog/svt_amba_common.uvm.pkg


//======================= top env path ===================================
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/inc
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/tb/
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/top
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/test
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/test/vseq
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/tb/reg_model
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/uvc/env_common
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/uvc/nr_l2dl_dtc_pld_agent
+incdir+$PROJ_WA/units/nr_l2_downlink/verif/bench/uvc/nr_l2dl_dtc_rdma_agent

//======================  commom   ========================================
+incdir+$PROJ_WA/units/verif_common/asr_uvm
+incdir+$PROJ_WA/units/verif_common/asr_uvm/asr_dst_fifo_agent
+incdir+$PROJ_WA/units/verif_common/asr_uvm/asr_src_fifo_agent


//======================= reuse rx_mac ===================================
+incdir+$PROJ_WA/units/nr_rx_mac/verif/bench/tb/
+incdir+$PROJ_WA/units/nr_rx_mac/verif/bench/uvc/rx_mac_tb_cmd_agent
+incdir+$PROJ_WA/units/nr_rx_mac/verif/bench/uvc/rx_mac_dma_agent
+incdir+$PROJ_WA/units/nr_rx_mac/verif/bench/uvc/regbus_agent
+incdir+$PROJ_WA/units/nr_rx_mac/verif/bench/uvc/rx_mac_mce_agent
+incdir+$PROJ_WA/units/nr_rx_mac/verif/bench/uvc/rx_mac_dl_node0_agent

$PROJ_WA/units/nr_l2_downlink/verif/bench/top/tb_top.sv
$PROJ_WA/units/nr_l2_downlink/verif/bench/top/hw_top.sv
