// Bind the RDI checker to the generated LogicalPhy without a simulation driver.
module logphy_formal_bind #(
    parameter int NBYTES = 64,
    parameter int NC = 32,
    parameter int SPEEDMODE_WIDTH = 4
) (
    input logic                       clock,
    input logic                       reset,
    input logic                       io_rdi_lpIrdy,
    input logic                       io_rdi_lpValid,
    input logic [NBYTES*8-1:0]        io_rdi_lpData,
    input logic                       io_rdi_plTrdy,
    input logic                       io_rdi_plValid,
    input logic [NBYTES*8-1:0]        io_rdi_plData,
    input logic [3:0]                 io_rdi_lpStateReq,
    input logic [3:0]                 io_rdi_plStateSts,
    input logic                       io_rdi_plInbandPres,
    input logic                       io_rdi_plPhyInRecenter,
    input logic                       io_rdi_lpLinkError,
    input logic                       io_rdi_plError,
    input logic                       io_rdi_plCError,
    input logic                       io_rdi_plNfError,
    input logic                       io_rdi_plTrainError,
    input logic                       io_rdi_plStallReq,
    input logic                       io_rdi_lpStallAck,
    input logic [SPEEDMODE_WIDTH-1:0] io_rdi_plSpeedmode,
    input logic                       io_rdi_plMaxSpeedmode,
    input logic [2:0]                 io_rdi_plLnkCfg,
    input logic                       io_rdi_plClkReq,
    input logic                       io_rdi_lpClkAck,
    input logic                       io_rdi_lpWakeReq,
    input logic                       io_rdi_plWakeAck,
    input logic [NC-1:0]              io_rdi_plCfg,
    input logic                       io_rdi_plCfgVld,
    input logic                       io_rdi_plCfgCrd,
    input logic [NC-1:0]              io_rdi_lpCfg,
    input logic                       io_rdi_lpCfgVld,
    input logic                       io_rdi_lpCfgCrd,
    input logic [3:0]                 io_status_ltState
);
    // The simulation wrapper also uses the DUT clock for RDI sampling.
    ucie_rdi_if #(.NBYTES(NBYTES), .NC(NC), .SPEEDMODE_WIDTH(SPEEDMODE_WIDTH))
        rdi (.reset(reset), .lclk(clock));

    assign rdi.lp_irdy          = io_rdi_lpIrdy;
    assign rdi.lp_valid         = io_rdi_lpValid;
    assign rdi.lp_data          = io_rdi_lpData;
    assign rdi.pl_trdy          = io_rdi_plTrdy;
    assign rdi.pl_valid         = io_rdi_plValid;
    assign rdi.pl_data          = io_rdi_plData;
    assign rdi.lp_state_req     = io_rdi_lpStateReq;
    assign rdi.pl_state_sts     = io_rdi_plStateSts;
    assign rdi.pl_inband_pres   = io_rdi_plInbandPres;
    assign rdi.pl_phyinrecenter = io_rdi_plPhyInRecenter;
    assign rdi.lp_linkerror     = io_rdi_lpLinkError;
    assign rdi.pl_error         = io_rdi_plError;
    assign rdi.pl_cerror        = io_rdi_plCError;
    assign rdi.pl_nferror       = io_rdi_plNfError;
    assign rdi.pl_trainerror    = io_rdi_plTrainError;
    assign rdi.pl_stallreq      = io_rdi_plStallReq;
    assign rdi.lp_stallack      = io_rdi_lpStallAck;
    assign rdi.pl_speedmode     = io_rdi_plSpeedmode;
    assign rdi.pl_max_speedmode = io_rdi_plMaxSpeedmode;
    assign rdi.pl_lnk_cfg       = io_rdi_plLnkCfg;
    assign rdi.pl_clk_req       = io_rdi_plClkReq;
    assign rdi.lp_clk_ack       = io_rdi_lpClkAck;
    assign rdi.lp_wake_req      = io_rdi_lpWakeReq;
    assign rdi.pl_wake_ack      = io_rdi_plWakeAck;
    assign rdi.pl_cfg           = io_rdi_plCfg;
    assign rdi.pl_cfg_vld       = io_rdi_plCfgVld;
    assign rdi.pl_cfg_crd       = io_rdi_plCfgCrd;
    assign rdi.lp_cfg           = io_rdi_lpCfg;
    assign rdi.lp_cfg_vld       = io_rdi_lpCfgVld;
    assign rdi.lp_cfg_crd       = io_rdi_lpCfgCrd;

    logphy_assertions rdi_assertions (.rdi(rdi), .lt_state(io_status_ltState));

    // Adapter input assumptions for the standalone PHY proof.
    localparam logic [3:0] RDI_RESET = 4'h0;
    localparam logic [3:0] RDI_LINKERROR = 4'ha;

    default clocking formal_clock @(posedge clock); endclocking

    assume_adapter_reset_exit:
    assume property ($fell(reset) |-> ({
        rdi.lp_irdy, rdi.lp_valid, rdi.lp_data, rdi.lp_state_req, rdi.lp_linkerror,
        rdi.lp_stallack, rdi.lp_clk_ack, rdi.lp_wake_req, rdi.lp_cfg, rdi.lp_cfg_vld, rdi.lp_cfg_crd
    } == '0));

    assume_adapter_state_request:
    assume property (disable iff (reset)
        rdi.lp_state_req inside {4'h0, 4'h1, 4'h4, 4'h8, 4'h9, 4'hb, 4'hc});

    assume_adapter_tx_valid:
    assume property (disable iff (reset) rdi.lp_valid |-> rdi.lp_irdy);

    assume_adapter_no_tx_in_reset:
    assume property (disable iff (reset)
        rdi.pl_state_sts == RDI_RESET && $past(rdi.pl_state_sts) != RDI_LINKERROR &&
        ($past(rdi.pl_state_sts) != RDI_RESET || !$past(rdi.lp_irdy)) |-> !rdi.lp_irdy);

    assume_adapter_reset_drain:
    assume property (disable iff (reset)
        $past(rdi.pl_state_sts) == RDI_LINKERROR && rdi.pl_state_sts == RDI_RESET && rdi.lp_irdy
        |-> s_eventually (!rdi.lp_irdy));

    assume_adapter_stall_ack_start:
    assume property (disable iff (reset)
        $rose(rdi.lp_stallack) |-> rdi.pl_stallreq && $past(rdi.pl_stallreq));

    assume_adapter_stall_ack_release:
    assume property (disable iff (reset)
        $fell(rdi.lp_stallack) |-> !rdi.pl_stallreq && !$past(rdi.pl_stallreq));

    assume_adapter_tx_stalled:
    assume property (disable iff (reset) rdi.lp_stallack |-> !rdi.lp_valid && !rdi.lp_irdy);

    assume_adapter_clock_ack_start:
    assume property (disable iff (reset)
        $rose(rdi.lp_clk_ack) |-> rdi.pl_clk_req && $past(rdi.pl_clk_req) && $past(rdi.pl_clk_req, 2));

    assume_adapter_clock_ack_release:
    assume property (disable iff (reset)
        $fell(rdi.lp_clk_ack) |-> !rdi.pl_clk_req && !$past(rdi.pl_clk_req));

    assume_adapter_clock_ack_progress:
    assume property (disable iff (reset)
        rdi.pl_clk_req |-> s_eventually (rdi.lp_clk_ack || !rdi.pl_clk_req));

    assume_adapter_wake_request_order:
    assume property (disable iff (reset) $rose(rdi.lp_wake_req) |-> !rdi.pl_wake_ack);

    assume_adapter_cfg_clocked:
    assume property (disable iff (reset)
        (rdi.pl_state_sts inside {4'h0, 4'h4, 4'h8, 4'h9, 4'hc}) &&
        (rdi.lp_cfg_vld || rdi.lp_cfg_crd) |-> rdi.lp_wake_req && rdi.pl_wake_ack);
endmodule

bind LogicalPhy logphy_formal_bind #(
    .NBYTES($bits(io_rdi_lpData) / 8),
    .NC($bits(io_rdi_lpCfg)),
    .SPEEDMODE_WIDTH($bits(io_rdi_plSpeedmode))
) formal_rdi_monitor (.*);
