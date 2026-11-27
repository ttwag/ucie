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

// --------------------------------------------------------
// LogPHY <> Local Electrical PHY: mainband and electrical control/status (DUT prefix: io_analog_)
// --------------------------------------------------------
interface logical_phy_afe_if (input logic reset, clock);

    // Mainband transmit data transfer
    // Data array index is the lane number; bits_valid is the PHY valid lane.
    logic                mainband_tx_ready;
    logic                mainband_tx_valid;
    logic [31:0]         mainband_tx_bits_data [15:0];
    logic [31:0]         mainband_tx_bits_valid;
    logic [31:0]         mainband_tx_bits_clkP;
    logic [31:0]         mainband_tx_bits_clkN;
    logic [31:0]         mainband_tx_bits_trk;

    // Mainband receive data transfer
    logic                mainband_rx_ready;
    logic                mainband_rx_valid;
    logic [31:0]         mainband_rx_bits_data [15:0];
    logic [31:0]         mainband_rx_bits_valid;
    logic [31:0]         mainband_rx_bits_clkP;
    logic [31:0]         mainband_rx_bits_clkN;
    logic [31:0]         mainband_rx_bits_trk;

    // Electrical PHY status
    logic                status_pllLock;
    logic                status_clocksUngatedAndStable;
    logic                status_txSelfCalDone;

    // Electrical PHY control: mainband transmit enables
    logic [15:0]         ctrl_mbTxDataEn;
    logic                ctrl_mbTxClkEn;
    logic                ctrl_mbTxValidEn;
    logic                ctrl_mbTxTrackEn;

    // Electrical PHY control: mainband receive enables
    logic [15:0]         ctrl_mbRxDataEn;
    logic                ctrl_mbRxClkEn;
    logic                ctrl_mbRxValidEn;
    logic                ctrl_mbRxTrackEn;

    // Electrical PHY control: sideband enables
    logic                ctrl_sbTxDataEn;
    logic                ctrl_sbTxClkEn;
    logic                ctrl_sbRxDataEn;
    logic                ctrl_sbRxClkEn;

    // Electrical PHY control: frequency, clock phase, and electrical idle
    logic [3:0]          ctrl_freqSel;
    logic [4:0]          ctrl_clockPhaseSelect;
    logic                ctrl_doElectricalIdleTx;
    logic                ctrl_doElectricalIdleRx;

    // Clocking blocks use the testbench clock for the parallel AFE signals.
`ifndef LOGPHY_FORMAL
    clocking logical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input mainband_tx_ready;
        output mainband_tx_valid;
        output mainband_tx_bits_data;
        output mainband_tx_bits_valid;
        output mainband_tx_bits_clkP;
        output mainband_tx_bits_clkN;
        output mainband_tx_bits_trk;
        output mainband_rx_ready;
        input mainband_rx_valid;
        input mainband_rx_bits_data;
        input mainband_rx_bits_valid;
        input mainband_rx_bits_clkP;
        input mainband_rx_bits_clkN;
        input mainband_rx_bits_trk;
        input status_pllLock;
        input status_clocksUngatedAndStable;
        input status_txSelfCalDone;
        output ctrl_mbTxDataEn;
        output ctrl_mbTxClkEn;
        output ctrl_mbTxValidEn;
        output ctrl_mbTxTrackEn;
        output ctrl_mbRxDataEn;
        output ctrl_mbRxClkEn;
        output ctrl_mbRxValidEn;
        output ctrl_mbRxTrackEn;
        output ctrl_sbTxDataEn;
        output ctrl_sbTxClkEn;
        output ctrl_sbRxDataEn;
        output ctrl_sbRxClkEn;
        output ctrl_freqSel;
        output ctrl_clockPhaseSelect;
        output ctrl_doElectricalIdleTx;
        output ctrl_doElectricalIdleRx;
    endclocking

    clocking electrical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        output mainband_tx_ready;
        input mainband_tx_valid;
        input mainband_tx_bits_data;
        input mainband_tx_bits_valid;
        input mainband_tx_bits_clkP;
        input mainband_tx_bits_clkN;
        input mainband_tx_bits_trk;
        input mainband_rx_ready;
        output mainband_rx_valid;
        output mainband_rx_bits_data;
        output mainband_rx_bits_valid;
        output mainband_rx_bits_clkP;
        output mainband_rx_bits_clkN;
        output mainband_rx_bits_trk;
        output status_pllLock;
        output status_clocksUngatedAndStable;
        output status_txSelfCalDone;
        input ctrl_mbTxDataEn;
        input ctrl_mbTxClkEn;
        input ctrl_mbTxValidEn;
        input ctrl_mbTxTrackEn;
        input ctrl_mbRxDataEn;
        input ctrl_mbRxClkEn;
        input ctrl_mbRxValidEn;
        input ctrl_mbRxTrackEn;
        input ctrl_sbTxDataEn;
        input ctrl_sbTxClkEn;
        input ctrl_sbRxDataEn;
        input ctrl_sbRxClkEn;
        input ctrl_freqSel;
        input ctrl_clockPhaseSelect;
        input ctrl_doElectricalIdleTx;
        input ctrl_doElectricalIdleRx;
    endclocking

    modport logical_phy (clocking logical_phy_cb);

    modport electrical_phy (clocking electrical_phy_cb);
`endif

endinterface

// --------------------------------------------------------
// LogPHY <> Remote Partner Model: sideband (DUT prefix: io_analog_sideband)
// --------------------------------------------------------
interface logical_phy_sideband_if (input logic reset, clock);

    // Sideband receive signals from the remote partner
    logic          sidebandLink_in_bits;
    logic          sidebandLink_in_fwClock;

    // Sideband transmit signals to the remote partner
    logic          sidebandLink_out_clk;
    logic          sidebandLink_out_d0;
    logic          sidebandLink_out_d1;
    logic          sidebandLink_out_fwClockD0;
    logic          sidebandLink_out_fwClockD1;

    // Clocking blocks use the testbench clock for the parallel sideband signals.
`ifndef LOGPHY_FORMAL
    clocking logical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input sidebandLink_in_bits;
        input sidebandLink_in_fwClock;
        output sidebandLink_out_clk;
        output sidebandLink_out_d0;
        output sidebandLink_out_d1;
        output sidebandLink_out_fwClockD0;
        output sidebandLink_out_fwClockD1;
    endclocking

    clocking remote_partner_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        output sidebandLink_in_bits;
        output sidebandLink_in_fwClock;
        input sidebandLink_out_clk;
        input sidebandLink_out_d0;
        input sidebandLink_out_d1;
        input sidebandLink_out_fwClockD0;
        input sidebandLink_out_fwClockD1;
    endclocking

    modport logical_phy (clocking logical_phy_cb);

    modport remote_partner (clocking remote_partner_cb);
`endif

endinterface

// --------------------------------------------------------
// Software / System Control Model <> LogPHY (DUT prefix: io_ctrl or io_status)
// --------------------------------------------------------
interface logical_phy_control_if (input logic clock, reset);

    // Power and training retry control
    logic          ctrl_pwrGood;
    logic [9:0]    ctrl_retryTrainingAmt;

    // Local PHY parameter settings
    logic          ctrl_localPhyParamSettings_valid;
    logic [4:0]    ctrl_localPhyParamSettings_bits_voltageSwing;
    logic [3:0]    ctrl_localPhyParamSettings_bits_maxDataRate;
    logic          ctrl_localPhyParamSettings_bits_clockMode;
    logic          ctrl_localPhyParamSettings_bits_clockPhase;
    logic          ctrl_localPhyParamSettings_bits_ucieSx8;
    logic          ctrl_localPhyParamSettings_bits_sbFeatExt;
    logic          ctrl_localPhyParamSettings_bits_txAdjRuntime;
    logic [1:0]    ctrl_localPhyParamSettings_bits_moduleId;

    // Link training pattern and comparison parameters
    logic [3:0]    ctrl_linkTrainingParameters_clockPhase;
    logic [2:0]    ctrl_linkTrainingParameters_dataPattern;
    logic [2:0]    ctrl_linkTrainingParameters_validPattern;
    logic          ctrl_linkTrainingParameters_patternMode;
    logic [15:0]   ctrl_linkTrainingParameters_iterationCount;
    logic [15:0]   ctrl_linkTrainingParameters_idleCount;
    logic [15:0]   ctrl_linkTrainingParameters_burstCount;
    logic [15:0]   ctrl_linkTrainingParameters_maxErrorThreshold;
    logic          ctrl_linkTrainingParameters_comparisonMode;

    // Software training requests and operating-parameter overrides
    logic          ctrl_swStartLinkTraining;
    logic          ctrl_swRetrainRequest;
    logic          ctrl_linkOpParamOverride;
    logic [4:0]    ctrl_clockPhaseSelect;
    logic [15:0]   ctrl_maxErrorThresholdPerLane;

    // Runtime link control and repair requests
    logic          ctrl_changeInRuntimeLinkCtrlRegsDetected;
    logic          ctrl_runtimeLinkCtrlBusyBit;
    logic          ctrl_runtimeRequestForRepair;

    // Link training state and error status
    logic [3:0]    status_ltState;
    logic [4:0]    status_currentState;
    logic          status_trainingTimedout;
    logic          status_fatalTrainingError;

    // Negotiated PHY parameter settings
    logic          status_negotiatedPhyParamSettings_valid;
    logic [4:0]    status_negotiatedPhyParamSettings_bits_voltageSwing;
    logic [3:0]    status_negotiatedPhyParamSettings_bits_maxDataRate;
    logic          status_negotiatedPhyParamSettings_bits_clockMode;
    logic          status_negotiatedPhyParamSettings_bits_clockPhase;
    logic          status_negotiatedPhyParamSettings_bits_ucieSx8;
    logic          status_negotiatedPhyParamSettings_bits_sbFeatExt;
    logic          status_negotiatedPhyParamSettings_bits_txAdjRuntime;
    logic [1:0]    status_negotiatedPhyParamSettings_bits_moduleId;

    // Link width, frequency, lane reversal, and lane masks
    logic [2:0]    status_linkWidth;
    logic [3:0]    status_freqSel;
    logic          status_doLaneReversal;
    logic          status_widthDegraded;
    logic [15:0]   status_txLaneMask;
    logic [15:0]   status_rxLaneMask;

    // Remote training-error request
    logic          status_remoteRequestingTrainError;

    // Sideband error and first-fault diagnostics
    logic          status_sideband_sbParityErrSeen;
    logic          status_sideband_sbRxPriorityQueuesFullSeen;
    logic          status_sideband_sbDeserializerTimedoutSeen;
    logic          status_sideband_sbInvalidRouteUpperSeen;
    logic          status_sideband_sbInvalidRouteCurrSeen;
    logic          status_sideband_sbInvalidRouteLowerSeen;
    logic          status_sideband_sbUnhandledCurrentLayerMsgSeen;
    logic          status_sideband_sbFirstFaultValid;
    logic [4:0]    status_sideband_sbFirstFaultOpcode;
    logic [63:0]   status_sideband_sbFirstFaultHeader;

`ifndef LOGPHY_FORMAL
    clocking logical_phy_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        input ctrl_pwrGood;
        input ctrl_retryTrainingAmt;
        input ctrl_localPhyParamSettings_valid;
        input ctrl_localPhyParamSettings_bits_voltageSwing;
        input ctrl_localPhyParamSettings_bits_maxDataRate;
        input ctrl_localPhyParamSettings_bits_clockMode;
        input ctrl_localPhyParamSettings_bits_clockPhase;
        input ctrl_localPhyParamSettings_bits_ucieSx8;
        input ctrl_localPhyParamSettings_bits_sbFeatExt;
        input ctrl_localPhyParamSettings_bits_txAdjRuntime;
        input ctrl_localPhyParamSettings_bits_moduleId;
        input ctrl_linkTrainingParameters_clockPhase;
        input ctrl_linkTrainingParameters_dataPattern;
        input ctrl_linkTrainingParameters_validPattern;
        input ctrl_linkTrainingParameters_patternMode;
        input ctrl_linkTrainingParameters_iterationCount;
        input ctrl_linkTrainingParameters_idleCount;
        input ctrl_linkTrainingParameters_burstCount;
        input ctrl_linkTrainingParameters_maxErrorThreshold;
        input ctrl_linkTrainingParameters_comparisonMode;
        input ctrl_swStartLinkTraining;
        input ctrl_swRetrainRequest;
        input ctrl_linkOpParamOverride;
        input ctrl_clockPhaseSelect;
        input ctrl_maxErrorThresholdPerLane;
        input ctrl_changeInRuntimeLinkCtrlRegsDetected;
        input ctrl_runtimeLinkCtrlBusyBit;
        input ctrl_runtimeRequestForRepair;
        output status_ltState;
        output status_currentState;
        output status_trainingTimedout;
        output status_fatalTrainingError;
        output status_negotiatedPhyParamSettings_valid;
        output status_negotiatedPhyParamSettings_bits_voltageSwing;
        output status_negotiatedPhyParamSettings_bits_maxDataRate;
        output status_negotiatedPhyParamSettings_bits_clockMode;
        output status_negotiatedPhyParamSettings_bits_clockPhase;
        output status_negotiatedPhyParamSettings_bits_ucieSx8;
        output status_negotiatedPhyParamSettings_bits_sbFeatExt;
        output status_negotiatedPhyParamSettings_bits_txAdjRuntime;
        output status_negotiatedPhyParamSettings_bits_moduleId;
        output status_linkWidth;
        output status_freqSel;
        output status_doLaneReversal;
        output status_widthDegraded;
        output status_txLaneMask;
        output status_rxLaneMask;
        output status_remoteRequestingTrainError;
        output status_sideband_sbParityErrSeen;
        output status_sideband_sbRxPriorityQueuesFullSeen;
        output status_sideband_sbDeserializerTimedoutSeen;
        output status_sideband_sbInvalidRouteUpperSeen;
        output status_sideband_sbInvalidRouteCurrSeen;
        output status_sideband_sbInvalidRouteLowerSeen;
        output status_sideband_sbUnhandledCurrentLayerMsgSeen;
        output status_sideband_sbFirstFaultValid;
        output status_sideband_sbFirstFaultOpcode;
        output status_sideband_sbFirstFaultHeader;
    endclocking

    clocking system_control_cb @(posedge clock);
        default input #1step output #1step;
        input reset;
        output ctrl_pwrGood;
        output ctrl_retryTrainingAmt;
        output ctrl_localPhyParamSettings_valid;
        output ctrl_localPhyParamSettings_bits_voltageSwing;
        output ctrl_localPhyParamSettings_bits_maxDataRate;
        output ctrl_localPhyParamSettings_bits_clockMode;
        output ctrl_localPhyParamSettings_bits_clockPhase;
        output ctrl_localPhyParamSettings_bits_ucieSx8;
        output ctrl_localPhyParamSettings_bits_sbFeatExt;
        output ctrl_localPhyParamSettings_bits_txAdjRuntime;
        output ctrl_localPhyParamSettings_bits_moduleId;
        output ctrl_linkTrainingParameters_clockPhase;
        output ctrl_linkTrainingParameters_dataPattern;
        output ctrl_linkTrainingParameters_validPattern;
        output ctrl_linkTrainingParameters_patternMode;
        output ctrl_linkTrainingParameters_iterationCount;
        output ctrl_linkTrainingParameters_idleCount;
        output ctrl_linkTrainingParameters_burstCount;
        output ctrl_linkTrainingParameters_maxErrorThreshold;
        output ctrl_linkTrainingParameters_comparisonMode;
        output ctrl_swStartLinkTraining;
        output ctrl_swRetrainRequest;
        output ctrl_linkOpParamOverride;
        output ctrl_clockPhaseSelect;
        output ctrl_maxErrorThresholdPerLane;
        output ctrl_changeInRuntimeLinkCtrlRegsDetected;
        output ctrl_runtimeLinkCtrlBusyBit;
        output ctrl_runtimeRequestForRepair;
        input status_ltState;
        input status_currentState;
        input status_trainingTimedout;
        input status_fatalTrainingError;
        input status_negotiatedPhyParamSettings_valid;
        input status_negotiatedPhyParamSettings_bits_voltageSwing;
        input status_negotiatedPhyParamSettings_bits_maxDataRate;
        input status_negotiatedPhyParamSettings_bits_clockMode;
        input status_negotiatedPhyParamSettings_bits_clockPhase;
        input status_negotiatedPhyParamSettings_bits_ucieSx8;
        input status_negotiatedPhyParamSettings_bits_sbFeatExt;
        input status_negotiatedPhyParamSettings_bits_txAdjRuntime;
        input status_negotiatedPhyParamSettings_bits_moduleId;
        input status_linkWidth;
        input status_freqSel;
        input status_doLaneReversal;
        input status_widthDegraded;
        input status_txLaneMask;
        input status_rxLaneMask;
        input status_remoteRequestingTrainError;
        input status_sideband_sbParityErrSeen;
        input status_sideband_sbRxPriorityQueuesFullSeen;
        input status_sideband_sbDeserializerTimedoutSeen;
        input status_sideband_sbInvalidRouteUpperSeen;
        input status_sideband_sbInvalidRouteCurrSeen;
        input status_sideband_sbInvalidRouteLowerSeen;
        input status_sideband_sbUnhandledCurrentLayerMsgSeen;
        input status_sideband_sbFirstFaultValid;
        input status_sideband_sbFirstFaultOpcode;
        input status_sideband_sbFirstFaultHeader;
    endclocking

    modport logical_phy (clocking logical_phy_cb);

    modport system_control (clocking system_control_cb);
`endif

endinterface
