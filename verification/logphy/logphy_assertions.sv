// UCIe 3.0 Table 10-1. This testbench uses lclk for both mainband and sideband.
module logphy_assertions (
    ucie_rdi_if rdi,
    input logic [3:0] lt_state
);
    timeunit 1ns; timeprecision 1ps;

    localparam logic [3:0] RDI_RESET     = 4'h0;  // NOP on lp_state_req
    localparam logic [3:0] RDI_ACTIVE    = 4'h1;
    localparam logic [3:0] RDI_PMNAK     = 4'h3;
    localparam logic [3:0] RDI_L1        = 4'h4;
    localparam logic [3:0] RDI_L2        = 4'h8;
    localparam logic [3:0] RDI_LINKRESET = 4'h9;
    localparam logic [3:0] RDI_LINKERROR = 4'ha;
    localparam logic [3:0] RDI_RETRAIN   = 4'hb;
    localparam logic [3:0] RDI_DISABLED  = 4'hc;

    // §10.1.3. Shared by the PHY error, recenter, and sideband checks.
    wire clock_gating_permitted = rdi.pl_state_sts inside {
        RDI_RESET, RDI_LINKRESET, RDI_DISABLED, RDI_L1, RDI_L2
    };

    // --------------------------------------------------------
    // Group 0: Reset and RDI clock
    // --------------------------------------------------------
    default clocking rdi_clock @(posedge rdi.lclk); endclocking

    // §10.1.1. The tested configuration resets both clock-gating requests to zero.
    // pl_lnk_cfg describes the operating width in Active and Retrain.

    // Group 0.1
    assert_reset_exit:
    assert property ($fell(rdi.reset) |-> ({
        rdi.lp_irdy, rdi.lp_valid, rdi.lp_data, rdi.lp_state_req, rdi.lp_linkerror,
        rdi.lp_stallack, rdi.lp_clk_ack, rdi.lp_wake_req, rdi.lp_cfg, rdi.lp_cfg_vld,
        rdi.lp_cfg_crd, rdi.pl_trdy, rdi.pl_valid, rdi.pl_data, rdi.pl_state_sts,
        rdi.pl_inband_pres, rdi.pl_error, rdi.pl_cerror, rdi.pl_nferror, rdi.pl_trainerror,
        rdi.pl_phyinrecenter, rdi.pl_stallreq, rdi.pl_speedmode, rdi.pl_max_speedmode,
        rdi.pl_clk_req, rdi.pl_wake_ack, rdi.pl_cfg, rdi.pl_cfg_vld, rdi.pl_cfg_crd
    } === '0))
    else $fatal(1, "Group 0.1: RDI signals must be zero at domain reset exit");

    // --------------------------------------------------------
    // Group 1: Mainband data transfer
    // --------------------------------------------------------
    // Keep the LinkError-to-Reset cleanup window open until lp_irdy goes low.
    logic reset_drain_allowed;
    always_ff @(posedge rdi.lclk) begin
        if (rdi.reset)
            reset_drain_allowed <= 1'b0;
        else if (rdi.pl_state_sts != RDI_RESET)
            reset_drain_allowed <= rdi.pl_state_sts == RDI_LINKERROR;
        else if (!rdi.lp_irdy)
            reset_drain_allowed <= 1'b0;
    end

    // Group 1.1
    assert_tx_idle_in_reset:
    assert property (disable iff (rdi.reset)
        rdi.pl_state_sts == RDI_RESET && !reset_drain_allowed |-> !rdi.lp_irdy)
    else $fatal(1, "Group 1.1: lp_irdy asserted in Reset outside the LinkError cleanup window");

    // Group 1.2
    assert_tx_reset_drain_completes:
    assert property (disable iff (rdi.reset)
        $past(rdi.pl_state_sts) == RDI_LINKERROR && rdi.pl_state_sts == RDI_RESET && rdi.lp_irdy
        |-> s_eventually (!rdi.lp_irdy))
    else $fatal(1, "Group 1.2: lp_irdy did not deassert after LinkError-to-Reset");

    // Group 1.3
    assert_tx_valid_has_initiator_ready:
    assert property (disable iff (rdi.reset) rdi.lp_valid |-> rdi.lp_irdy)
    else $fatal(1, "Group 1.3: Adapter asserted lp_valid to send data without lp_irdy");

    // Group 1.4
    assert_tx_ready_state:
    assert property (disable iff (rdi.reset) rdi.pl_trdy |->
        rdi.pl_state_sts == RDI_ACTIVE ||
        (rdi.pl_state_sts == RDI_LINKERROR && (rdi.pl_stallreq || rdi.lp_stallack)))
    else $fatal(1, "Group 1.4: pl_trdy asserted outside Active or a LinkError stall handshake");

    // Group 1.5
    assert_tx_payload_known:
    assert property (disable iff (rdi.reset)
        rdi.lp_irdy && rdi.lp_valid && rdi.pl_trdy |-> !$isunknown(rdi.lp_data))
    else $fatal(1, "Group 1.5: Unknown lp_data on an accepted mainband transfer");

    // Group 1.6
    assert_rx_payload_known:
    assert property (disable iff (rdi.reset)
        rdi.pl_valid && !rdi.pl_error |-> !$isunknown(rdi.pl_data))
    else $fatal(1, "Group 1.6: Unknown pl_data on a valid mainband transfer without a framing error");

    // --------------------------------------------------------
    // Group 2: Link state and training control
    // --------------------------------------------------------
    // Group 2.1
    assert_state_request_encoding:
    assert property (disable iff (rdi.reset)
        !$isunknown(rdi.lp_state_req) &&
        (rdi.lp_state_req inside {RDI_RESET, RDI_ACTIVE, RDI_L1, RDI_L2, RDI_LINKRESET, RDI_RETRAIN, RDI_DISABLED}))
    else $fatal(1, "Group 2.1: Reserved lp_state_req encoding");

    // Group 2.2
    assert_state_status_encoding:
    assert property (disable iff (rdi.reset) !$isunknown(rdi.pl_state_sts) &&
        (rdi.pl_state_sts inside {
            RDI_RESET, RDI_ACTIVE, RDI_PMNAK, RDI_L1, RDI_L2, RDI_LINKRESET,
            RDI_LINKERROR, RDI_RETRAIN, RDI_DISABLED
        }))
    else $fatal(1, "Group 2.2: Reserved pl_state_sts encoding");

    // Encoding of the generated DUT's ltState output (LTState in utils/Types.scala).
    localparam logic [3:0] LT_RESET      = 4'd0;
    localparam logic [3:0] LT_TRAINERROR = 4'd7;

    // Group 2.3
    assert_inband_presence_held:
    assert property (disable iff (rdi.reset) $fell(rdi.pl_inband_pres) |->
        (lt_state inside {LT_RESET, LT_TRAINERROR}) ||
        ($past(lt_state) inside {LT_RESET, LT_TRAINERROR}))
    else $fatal(1, "Group 2.3: pl_inband_pres dropped without the training state machine losing the link");

    // Group 2.4
    assert_recenter_clock_handshake:
    assert property (disable iff (rdi.reset)
        clock_gating_permitted && $rose(rdi.pl_phyinrecenter) |->
        s_eventually (rdi.pl_clk_req && rdi.lp_clk_ack))
    else $fatal(1, "Group 2.4: PHY did not complete the Adapter clock handshake for pl_phyinrecenter");

    // --------------------------------------------------------
    // Group 3: Adapter/PHY error reporting and containment
    // --------------------------------------------------------
    // LinkError entry is shared by Adapter and PHY fatal errors.
    // Group 3.1
    assert_link_error_entry:
    assert property (disable iff (rdi.reset)
        ($rose(rdi.lp_linkerror) || $rose(rdi.pl_trainerror)) |->
        s_eventually (rdi.pl_state_sts == RDI_LINKERROR))
    else $fatal(1, "Group 3.1: RDI did not enter LinkError after an Adapter or PHY fatal error");

    // Group 3.2
    assert_adapter_link_error_held:
    assert property (disable iff (rdi.reset)
        $past(rdi.pl_state_sts) == RDI_LINKERROR && rdi.lp_linkerror |->
        rdi.pl_state_sts == RDI_LINKERROR)
    else $fatal(1, "Group 3.2: RDI left LinkError while lp_linkerror was asserted");

    // Group 3.3
    assert_framing_error_state:
    assert property (disable iff (rdi.reset) rdi.pl_error |-> rdi.pl_state_sts == RDI_ACTIVE)
    else $fatal(1, "Group 3.3: pl_error asserted outside Active");

    logic rx_recovery_pending;
    logic rx_retrain_seen;
    wire rx_recovered = rx_retrain_seen && rdi.pl_state_sts == RDI_ACTIVE;
    always_ff @(posedge rdi.lclk) begin
        if (rdi.reset || rdi.pl_state_sts == RDI_RESET) begin
            rx_recovery_pending <= 1'b0;
            rx_retrain_seen <= 1'b0;
        end else if (rdi.pl_error) begin
            rx_recovery_pending <= 1'b1;
            rx_retrain_seen <= 1'b0;
        end else if (rx_recovered) begin
            rx_recovery_pending <= 1'b0;
            rx_retrain_seen <= 1'b0;
        end else if (rx_recovery_pending && rdi.pl_state_sts == RDI_RETRAIN) begin
            rx_retrain_seen <= 1'b1;
        end
    end

    // Group 3.4
    assert_rx_waits_for_retrain:
    assert property (disable iff (rdi.reset)
        rx_recovery_pending && !rx_recovered && rdi.pl_valid |-> rdi.pl_error)
    else $fatal(1, "Group 3.4: PHY forwarded clean mainband data before recovery from a framing error");

    // Group 3.5
    assert_phy_error_clocked:
    assert property (disable iff (rdi.reset)
        clock_gating_permitted && (rdi.pl_cerror || rdi.pl_nferror) |->
        rdi.pl_clk_req && rdi.lp_clk_ack)
    else $fatal(1, "Group 3.5: PHY error was presented before the Adapter clock handshake completed");

    // Group 3.6
    assert_fatal_error_held:
    assert property (disable iff (rdi.reset) $rose(rdi.pl_trainerror) |->
        (rdi.pl_trainerror until
            ($past(rdi.pl_state_sts) == RDI_LINKERROR && rdi.pl_state_sts == RDI_RESET)))
    else $fatal(1, "Group 3.6: pl_trainerror cleared before RDI transitioned from LinkError to Reset");

    // --------------------------------------------------------
    // Group 4: Stalling before state transitions
    // --------------------------------------------------------
    // §10.3.2. Sample each phase on lclk. The Adapter can insert a delay before acknowledging.

    // Group 4.1
    assert_stall_req_start:
    assert property (disable iff (rdi.reset) 
        $rose(rdi.pl_stallreq) |-> !rdi.lp_stallack)
    else $fatal(1, "Group 4.1: pl_stallreq rose before lp_stallack was low");

    // Group 4.2
    assert_stall_ack_start:
    assert property (disable iff (rdi.reset)
        $rose(rdi.lp_stallack) |-> rdi.pl_stallreq && $past(rdi.pl_stallreq))
    else $fatal(1, "Group 4.2: lp_stallack rose without a preceding pl_stallreq");

    // Group 4.3
    assert_stall_req_release:
    assert property (disable iff (rdi.reset)
        $fell(rdi.pl_stallreq) |-> rdi.lp_stallack && $past(rdi.lp_stallack))
    else $fatal(1, "Group 4.3: pl_stallreq fell before lp_stallack was asserted");

    // Group 4.4
    assert_stall_ack_release:
    assert property (disable iff (rdi.reset)
        $fell(rdi.lp_stallack) |-> !rdi.pl_stallreq && !$past(rdi.pl_stallreq))
    else $fatal(1, "Group 4.4: lp_stallack fell before pl_stallreq was released");

    // Group 4.5
    assert_tx_stalled:
    assert property (disable iff (rdi.reset) rdi.lp_stallack |-> !rdi.lp_valid && !rdi.lp_irdy)
    else $fatal(1, "Group 4.5: Adapter presented mainband data while acknowledging a stall");

    // --------------------------------------------------------
    // Group 5: Link speed and width information
    // --------------------------------------------------------
    // Group 5.1
    assert_link_speed_and_width:
    assert property (disable iff (rdi.reset)
        (rdi.pl_state_sts inside {RDI_ACTIVE, RDI_RETRAIN}) |->
        !$isunknown({rdi.pl_speedmode, rdi.pl_lnk_cfg}) &&
        rdi.pl_speedmode <= 7 && rdi.pl_lnk_cfg <= 3'd6)
    else $fatal(1, "Group 5.1: Invalid pl_speedmode or pl_lnk_cfg in Active or Retrain");

    // Group 5.2
    assert_max_speed_changes_only_in_reset:
    assert property (disable iff (rdi.reset)
        $changed(rdi.pl_max_speedmode) |-> rdi.pl_state_sts == RDI_RESET)
    else $fatal(1, "Group 5.2: pl_max_speedmode changed outside Reset");

    // --------------------------------------------------------
    // Group 6: Clock gating and wake-up handshakes
    // --------------------------------------------------------
    // §10.1.3. Ack must lag both edges of its request. The rising edge has a bubble cycle.

    // Group 6.1
    assert_clk_ack_order:
    assert property (disable iff (rdi.reset)
        $rose(rdi.lp_clk_ack) |->
        rdi.pl_clk_req && $past(rdi.pl_clk_req) && $past(rdi.pl_clk_req, 2))
    else $fatal(1, "Group 6.1: lp_clk_ack rose without pl_clk_req and its required bubble");

    // Group 6.2
    assert_clk_ack_release:
    assert property (disable iff (rdi.reset)
        $fell(rdi.lp_clk_ack) |-> !rdi.pl_clk_req && !$past(rdi.pl_clk_req))
    else $fatal(1, "Group 6.2: lp_clk_ack fell before pl_clk_req was released");

    // §10.1.3.1. The DUT implements this handshake in RDIWakeHandshakeResponder.scala.
    // Rule 4 needs visibility into the internal clock-gating decision.
    // Rule 5 permits state and link-error requests before wake acknowledgment.
    // For rule 6, assert_adapter_cfg_clocked checks valid cfg beats in clock-gatable states.
    // Group 6.3
    assert_wake_bubble:
    assert property (disable iff (rdi.reset)
        $rose(rdi.lp_wake_req) |-> !rdi.pl_wake_ack ##1 !rdi.pl_wake_ack)
    else $fatal(1, "Group 6.3: pl_wake_ack rose before the required bubble");

    // Group 6.4
    assert_wake_ack_order:
    assert property (disable iff (rdi.reset)
        $rose(rdi.pl_wake_ack) |->
        rdi.lp_wake_req && $past(rdi.lp_wake_req) && $past(rdi.lp_wake_req, 2))
    else $fatal(1, "Group 6.4: pl_wake_ack rose without an earlier lp_wake_req");

    // Group 6.5
    assert_wake_ack_release:
    assert property (disable iff (rdi.reset)
        $fell(rdi.pl_wake_ack) |-> !rdi.lp_wake_req && !$past(rdi.lp_wake_req))
    else $fatal(1, "Group 6.5: pl_wake_ack fell before lp_wake_req was released");

    // // Preserve the directed wake test's local simulation timeout.
    // localparam int WAKE_ACK_TIMEOUT_CYCLES = 100;

    // // Group 6.6
    // assert_wake_ack_high_timeout:
    // assert property (disable iff (rdi.reset)
    //     $rose(rdi.lp_wake_req) |-> ##[2:WAKE_ACK_TIMEOUT_CYCLES] rdi.pl_wake_ack)
    // else $fatal(1, "Group 6.6: pl_wake_ack did not arrive within the testbench timeout");

    // // Group 6.7
    // assert_wake_ack_low_timeout:
    // assert property (disable iff (rdi.reset)
    //     $fell(rdi.lp_wake_req) |-> ##[1:WAKE_ACK_TIMEOUT_CYCLES] !rdi.pl_wake_ack)
    // else $fatal(1, "Group 6.7: pl_wake_ack did not clear within the testbench timeout");

    // --------------------------------------------------------
    // Group 7: Sideband packet transport and credits: PHY to adapter
    // --------------------------------------------------------
    // Both directions share NC. The clock-gating rules apply to cfg data and credit returns.
    initial begin
        // Group 7.1
        assert ($bits(rdi.lp_cfg) inside {8, 16, 32})
        else $fatal(1, "Group 7.1: RDI cfg width must be 8, 16 or 32 bits");
    end

    // Group 7.2
    assert_phy_cfg_clocked:
    assert property (disable iff (rdi.reset)
        clock_gating_permitted && (rdi.pl_cfg_vld || rdi.pl_cfg_crd) |->
        rdi.pl_clk_req && rdi.lp_clk_ack)
    else $fatal(1, "Group 7.2: PHY sent a cfg beat or credit before the Adapter clock handshake completed");

    // Group 7.3
    assert_phy_cfg_payload_known:
    assert property (disable iff (rdi.reset) rdi.pl_cfg_vld |-> !$isunknown(rdi.pl_cfg))
    else $fatal(1, "Group 7.3: Unknown pl_cfg on a valid sideband beat");

    // --------------------------------------------------------
    // Group 8: Sideband packet transport and credits: adapter to PHY
    // --------------------------------------------------------
    // Group 8.1
    assert_adapter_cfg_clocked:
    assert property (disable iff (rdi.reset)
        clock_gating_permitted && (rdi.lp_cfg_vld || rdi.lp_cfg_crd) |->
        rdi.lp_wake_req && rdi.pl_wake_ack)
    else $fatal(1, "Group 8.1: Adapter sent a cfg beat or credit before the PHY clock handshake completed");

    // Group 8.2
    assert_adapter_cfg_payload_known:
    assert property (disable iff (rdi.reset) rdi.lp_cfg_vld |-> !$isunknown(rdi.lp_cfg))
    else $fatal(1, "Group 8.2: Unknown lp_cfg on a valid sideband beat");
endmodule
