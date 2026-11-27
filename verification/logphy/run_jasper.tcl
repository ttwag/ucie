# Launch with jaspergold -batch -tcl run_jasper.tcl, or source it in Jasper.
set verify_dir [file dirname [file normalize [info script]]]
set rtl_dir [file normalize [file join $verify_dir .. .. scala generatedVerilog logphy]]

if {![file isfile [file join $rtl_dir filelist.f]]} {
    error "Generated LogPHY RTL is missing. Run 'make -C [list $verify_dir] rtl' first."
}

clear -all

# The generated filelist contains paths relative to rtl_dir.
set launch_dir [pwd]
set analyze_status [catch {
    cd $rtl_dir
    analyze -sv12 +define+LOGPHY_FORMAL +incdir+. -f filelist.f \
        [file join $verify_dir logphy_interface.sv] \
        [file join $verify_dir logphy_assertions.sv] \
        [file join $verify_dir logphy_formal_bind.sv]
} analyze_message analyze_options]
cd $launch_dir
if {$analyze_status != 0} {
    return -options $analyze_options $analyze_message
}

elaborate -top LogicalPhy -enable_sva_isunknown

# The monitor samples the local DUT clock. Sideband RX samples the falling
# edge of the forwarded clock supplied by the link partner.
clock clock
clock ~io_analog_sidebandLink_in_fwClock
reset -expression {reset == 1'b1}

prove -all
report -summary


