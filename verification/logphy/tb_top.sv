module tb_top;
  timeunit 1ns; timeprecision 1ps;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic clocks_ready = 1'b0;

  always #5ns clock = ~clock;

  // Create the four interface instances.
  ucie_rdi_if rdi (
      .reset(reset),
      .lclk (clock)
  );

  logical_phy_afe_if afe (
      .reset(reset),
      .clock(clock)
  );

  logical_phy_sideband_if sideband (
      .reset(reset),
      .clock(clock)
  );

  logical_phy_control_if ctrl (
      .clock(clock),
      .reset(reset)
  );

  logphy_wrapper dut (.*);
  logphy_assertions rdi_assertions (.rdi(rdi), .lt_state(ctrl.status_ltState));

  task automatic drive_rdi_idle();
    rdi.lp_irdy = 'b0;
    rdi.lp_valid = 'b0;
    rdi.lp_data = 'b0;
    rdi.lp_state_req = 'b0;
    rdi.lp_linkerror = 'b0;
    rdi.lp_stallack = 'b0;
    rdi.lp_clk_ack = 'b0;
    rdi.lp_wake_req = 'b0;
    rdi.lp_cfg = 'b0;
    rdi.lp_cfg_vld = 'b0;
    rdi.lp_cfg_crd = 'b0;
  endtask

  task automatic randomize_afe_inputs();
    afe.mainband_tx_ready = $urandom_range(1, 0);
    afe.mainband_rx_valid = $urandom_range(1, 0);

    foreach (afe.mainband_rx_bits_data[lane]) begin
      afe.mainband_rx_bits_data[lane] = $urandom();
    end

    afe.mainband_rx_bits_valid        = $urandom();
    afe.mainband_rx_bits_clkP         = $urandom();
    afe.mainband_rx_bits_clkN         = $urandom();
    afe.mainband_rx_bits_trk          = $urandom();

    afe.status_pllLock                = $urandom_range(1, 0);
    afe.status_clocksUngatedAndStable = $urandom_range(1, 0);
    afe.status_txSelfCalDone          = $urandom_range(1, 0);
  endtask

  task automatic randomize_sideband_inputs();
    sideband.sidebandLink_in_bits = $urandom_range(1, 0);
    sideband.sidebandLink_in_fwClock = $urandom_range(1, 0);
  endtask

  task automatic randomize_ctrl_inputs();
    ctrl.ctrl_pwrGood                                  = $urandom_range(1, 0);
    ctrl.ctrl_retryTrainingAmt                         = $urandom();

    ctrl.ctrl_localPhyParamSettings_valid              = $urandom_range(1, 0);
    ctrl.ctrl_localPhyParamSettings_bits_voltageSwing  = $urandom();
    ctrl.ctrl_localPhyParamSettings_bits_maxDataRate   = $urandom();
    ctrl.ctrl_localPhyParamSettings_bits_clockMode     = $urandom_range(1, 0);
    ctrl.ctrl_localPhyParamSettings_bits_clockPhase    = $urandom_range(1, 0);
    ctrl.ctrl_localPhyParamSettings_bits_ucieSx8       = $urandom_range(1, 0);
    ctrl.ctrl_localPhyParamSettings_bits_sbFeatExt     = $urandom_range(1, 0);
    ctrl.ctrl_localPhyParamSettings_bits_txAdjRuntime  = $urandom_range(1, 0);
    ctrl.ctrl_localPhyParamSettings_bits_moduleId      = $urandom();

    ctrl.ctrl_linkTrainingParameters_clockPhase        = $urandom();
    ctrl.ctrl_linkTrainingParameters_dataPattern       = $urandom();
    ctrl.ctrl_linkTrainingParameters_validPattern      = $urandom();
    ctrl.ctrl_linkTrainingParameters_patternMode       = $urandom_range(1, 0);
    ctrl.ctrl_linkTrainingParameters_iterationCount    = $urandom();
    ctrl.ctrl_linkTrainingParameters_idleCount         = $urandom();
    ctrl.ctrl_linkTrainingParameters_burstCount        = $urandom();
    ctrl.ctrl_linkTrainingParameters_maxErrorThreshold = $urandom();
    ctrl.ctrl_linkTrainingParameters_comparisonMode    = $urandom_range(1, 0);

    ctrl.ctrl_swStartLinkTraining                      = $urandom_range(1, 0);
    ctrl.ctrl_swRetrainRequest                         = $urandom_range(1, 0);
    ctrl.ctrl_linkOpParamOverride                      = $urandom_range(1, 0);
    ctrl.ctrl_clockPhaseSelect                         = $urandom();
    ctrl.ctrl_maxErrorThresholdPerLane                 = $urandom();
    ctrl.ctrl_changeInRuntimeLinkCtrlRegsDetected      = $urandom_range(1, 0);
    ctrl.ctrl_runtimeLinkCtrlBusyBit                   = $urandom_range(1, 0);
    ctrl.ctrl_runtimeRequestForRepair                  = $urandom_range(1, 0);
  endtask

  task automatic reset_dut();
    // drive all rdi lp signals to zero
    drive_rdi_idle();

    // randomize unrelated afe, sideband, ctrl input signals
    randomize_afe_inputs();
    randomize_sideband_inputs();
    randomize_ctrl_inputs();

    // trigger reset
    reset = 1'b1;
    @(posedge clock);
    @(negedge clock);
    reset = 1'b0;
    @(posedge clock);
    @(negedge clock);
  endtask

  task automatic test_rdi_wake_with_clocks_ready();
    @(negedge clock);
    rdi.lp_wake_req = 1'b1;
    afe.status_clocksUngatedAndStable = 1'b0;
    repeat ($urandom_range(8, 1)) @(posedge clock);  // Model a delayed PHY clock
    if (rdi.pl_wake_ack !== 1'b0) $fatal(1, "pl_wake_ack asserted before PHY clocks were ready");
    @(negedge clock);
    afe.status_clocksUngatedAndStable = 1'b1;
    wait (rdi.pl_wake_ack === 1'b1);

    repeat ($urandom_range(8, 1)) @(posedge clock);  // Keep lp_wake_req high for more samples

    @(negedge clock);
    rdi.lp_wake_req = 1'b0;
    wait (rdi.pl_wake_ack === 1'b0);
  endtask

  initial begin
    reset_dut();
    test_rdi_wake_with_clocks_ready();
    $display("PASS: LogPHY tests");
    $finish;
  end
endmodule
