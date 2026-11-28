// LOGPHY_FORMAL omits the simulation clocking views while retaining raw signals.
// --------------------------------------------------------
// Adapter <> LogPHY Interface (DUT prefix: io_rdi_)
// --------------------------------------------------------
interface ucie_rdi_if #(
    parameter int unsigned NBYTES = 64,
    parameter int unsigned NC = 32,
    parameter int unsigned SPEEDMODE_WIDTH = 4
) (
    // Reset and RDI clock
    input logic reset,
    input logic lclk
);

    // Mainband data transfer
    logic                         lp_irdy;
    logic                         lp_valid;
    logic [NBYTES-1:0][7:0]       lp_data;
    logic                         pl_trdy;
    logic                         pl_valid;
    logic [NBYTES-1:0][7:0]       pl_data;

    // Link state and training control
    logic [3:0] lp_state_req;
    logic [3:0] pl_state_sts;
    logic       pl_inband_pres;
    logic       pl_phyinrecenter;

    // Adapter/PHY error reporting and containment
    logic lp_linkerror;
    logic pl_error;
    logic pl_cerror;
    logic pl_nferror;
    logic pl_trainerror;

    // Stalling before state transitions
    logic pl_stallreq;
    logic lp_stallack;

    // Link speed and width information
    logic [SPEEDMODE_WIDTH-1:0] pl_speedmode;
    logic                       pl_max_speedmode;
    logic [2:0]                 pl_lnk_cfg;

    // Clock gating and wake-up handshakes
    logic pl_clk_req;
    logic lp_clk_ack;
    logic lp_wake_req;
    logic pl_wake_ack;

    // Sideband packet transport and credits: PHY to adapter
    logic [NC-1:0] pl_cfg;
    logic          pl_cfg_vld;
    logic          pl_cfg_crd;

    // Sideband packet transport and credits: adapter to PHY
    logic [NC-1:0] lp_cfg;
    logic          lp_cfg_vld;
    logic          lp_cfg_crd;

`ifndef LOGPHY_FORMAL
    clocking logical_phy_cb @(posedge lclk);
        default input #1step output #1step;
        input reset;
        input lp_irdy;
        input lp_valid;
        input lp_data;
        output pl_trdy;
        output pl_valid;
        output pl_data;
        input lp_state_req;
        input lp_linkerror;
        output pl_state_sts;
        output pl_inband_pres;
        output pl_error;
        output pl_cerror;
        output pl_nferror;
        output pl_trainerror;
        output pl_phyinrecenter;
        output pl_stallreq;
        input lp_stallack;
        output pl_speedmode;
        output pl_max_speedmode;
        output pl_lnk_cfg;
        output pl_clk_req;
        input lp_clk_ack;
        input lp_wake_req;
        output pl_wake_ack;
        output pl_cfg;
        output pl_cfg_vld;
        output pl_cfg_crd;
        input lp_cfg;
        input lp_cfg_vld;
        input lp_cfg_crd;
    endclocking

    clocking adapter_cb @(posedge lclk);
        default input #1step output #1step;
        input reset;
        output lp_irdy;
        output lp_valid;
        output lp_data;
        input pl_trdy;
        input pl_valid;
        input pl_data;
        output lp_state_req;
        output lp_linkerror;
        input pl_state_sts;
        input pl_inband_pres;
        input pl_error;
        input pl_cerror;
        input pl_nferror;
        input pl_trainerror;
        input pl_phyinrecenter;
        input pl_stallreq;
        output lp_stallack;
        input pl_speedmode;
        input pl_max_speedmode;
        input pl_lnk_cfg;
        input pl_clk_req;
        output lp_clk_ack;
        output lp_wake_req;
        input pl_wake_ack;
        input pl_cfg;
        input pl_cfg_vld;
        input pl_cfg_crd;
        output lp_cfg;
        output lp_cfg_vld;
        output lp_cfg_crd;
    endclocking

    modport logical_phy (clocking logical_phy_cb);

    modport adapter (clocking adapter_cb);
`endif

endinterface

// System control inputs (io_ctrl_*).
interface logical_phy_control_if (input logic clock, reset);

    // Link training, runtime control, and repair requests.
    struct packed {
        logic pwrGood;
        logic [9:0] retryTrainingAmt;
        logic swStartLinkTraining;
        logic swRetrainRequest;
        logic linkOpParamOverride;
        logic [4:0] clockPhaseSelect;
        logic [15:0] maxErrorThresholdPerLane;
        logic changeInRuntimeLinkCtrlRegsDetected;
        logic runtimeLinkCtrlBusyBit;
        logic runtimeRequestForRepair;
    } link_control;

    // Local advertisement for the MBINIT.PARAM exchange.
    struct packed {
        logic valid;
        logic [4:0] voltageSwing;
        logic [3:0] maxDataRate;
        logic clockMode;
        logic clockPhase;
        logic ucieSx8;
        logic sbFeatExt;
        logic txAdjRuntime;
        logic [1:0] moduleId;
    } local_params;

    // Pattern and comparison settings used by the override.
    struct packed {
        logic [3:0] clockPhase;
        logic [2:0] dataPattern;
        logic [2:0] validPattern;
        logic patternMode;
        logic [15:0] iterationCount;
        logic [15:0] idleCount;
        logic [15:0] burstCount;
        logic [15:0] maxErrorThreshold;
        logic comparisonMode;
    } training_params;

`ifndef LOGPHY_FORMAL
    clocking logical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input link_control, local_params, training_params;
    endclocking

    clocking system_control_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        output link_control, local_params, training_params;
    endclocking

    modport logical_phy (clocking logical_phy_cb);
    modport system_control (clocking system_control_cb);
`endif
endinterface

// Logical PHY status outputs (io_status_*).
interface logical_phy_status_if (input logic clock, reset);

    // Training stage, substate, and errors.
    struct packed {
        logic [3:0] ltState;
        logic [4:0] currentState;
        logic trainingTimedout;
        logic fatalTrainingError;
        logic remoteRequestingTrainError;
    } training;

    // Parameters reported after the sideband exchange.
    struct packed {
        logic valid;
        logic [4:0] voltageSwing;
        logic [3:0] maxDataRate;
        logic clockMode;
        logic clockPhase;
        logic ucieSx8;
        logic sbFeatExt;
        logic txAdjRuntime;
        logic [1:0] moduleId;
    } negotiated_params;

    // Operating speed, width, and active lanes.
    struct packed {
        logic [2:0] linkWidth;
        logic [3:0] freqSel;
        logic doLaneReversal;
        logic widthDegraded;
        logic [15:0] txLaneMask;
        logic [15:0] rxLaneMask;
    } link;

    // Sideband errors and first-fault diagnostics.
    struct packed {
        logic sbParityErrSeen;
        logic sbRxPriorityQueuesFullSeen;
        logic sbDeserializerTimedoutSeen;
        logic sbInvalidRouteUpperSeen;
        logic sbInvalidRouteCurrSeen;
        logic sbInvalidRouteLowerSeen;
        logic sbUnhandledCurrentLayerMsgSeen;
        logic sbFirstFaultValid;
        logic [4:0] sbFirstFaultOpcode;
        logic [63:0] sbFirstFaultHeader;
    } sideband;

`ifndef LOGPHY_FORMAL
    clocking logical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        output training, negotiated_params, link, sideband;
    endclocking

    clocking system_status_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input training, negotiated_params, link, sideband;
    endclocking

    modport logical_phy (clocking logical_phy_cb);
    modport system_status (clocking system_status_cb);
`endif
endinterface

// Logical PHY to Electrical PHY and link-partner model (io_analog_*).
interface logical_phy_analog_if (input logic clock, reset);

    // Mainband ready signals are driven by the receiver of each beat.
    logic mainband_tx_ready;
    logic mainband_rx_ready;

    // The valid flag qualifies the beat. valid_lane carries the physical lane word.
    typedef struct packed {
        logic valid;
        logic [15:0][31:0] data;
        logic [31:0] valid_lane;
        logic [31:0] clkP;
        logic [31:0] clkN;
        logic [31:0] trk;
    } mainband_beat_t;

    mainband_beat_t mainband_tx;
    mainband_beat_t mainband_rx;

    // Serial receive data and forwarded clock from the partner model.
    struct packed {
        logic bits;
        logic fwClock;
    } sideband_rx;

    // Half-rate transmit data and forwarded-clock inputs to the bump drivers.
    struct packed {
        logic clk;
        logic d0;
        logic d1;
        logic fwClockD0;
        logic fwClockD1;
    } sideband_tx;

    // Electrical PHY feedback to the Logical PHY.
    struct packed {
        logic pllLock;
        logic clocksUngatedAndStable;
        logic txSelfCalDone;
    } status;

    // Electrical controls driven by the Logical PHY.
    struct packed {
        // Mainband lane enables and forwarded-clock gating.
        logic [15:0] mbTxDataEn;
        logic mbTxClkEn;
        logic mbTxValidEn;
        logic mbTxTrackEn;
        logic [15:0] mbRxDataEn;
        logic mbRxClkEn;
        logic mbRxValidEn;
        logic mbRxTrackEn;

        // Sideband data and forwarded-clock enables.
        logic sbTxDataEn;
        logic sbTxClkEn;
        logic sbRxDataEn;
        logic sbRxClkEn;

        // Speed, phase, and electrical idle.
        logic [3:0] freqSel;
        logic [4:0] clockPhaseSelect;
        logic doElectricalIdleTx;
        logic doElectricalIdleRx;
        logic mbTxClkGate;
    } ctrl;

`ifndef LOGPHY_FORMAL
    clocking logical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input mainband_tx_ready, mainband_rx, status, sideband_rx;
        output mainband_rx_ready, mainband_tx, ctrl, sideband_tx;
    endclocking

    clocking electrical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input mainband_rx_ready, mainband_tx, ctrl;
        output mainband_tx_ready, mainband_rx, status;
    endclocking

    clocking remote_partner_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input sideband_tx;
        output sideband_rx;
    endclocking

    modport logical_phy (clocking logical_phy_cb);
    modport electrical_phy (clocking electrical_phy_cb);
    modport remote_partner (clocking remote_partner_cb);
`endif
endinterface
