set currentDir [pwd]
puts "Work Dir: $currentDir"
set all_generics [get_property generic [get_filesets sim_1]]

regexp {numOfBit=(\d+)} $all_generics -> extracted_bit
regexp {numOfLine=(\d+)} $all_generics -> extracted_line
regexp {accumulationNumber=(\d+)} $all_generics -> extracted_acc

set curr_wave [current_wave_config]
if { [string length $curr_wave] == 0 } {
if { [llength [get_objects]] > 0} {
    add_wave /
    add_wave /averageToRam_tb/uut/*
    set_property needs_save false [current_wave_config]
} else {
    send_msg_id Add_Wave-1 WARNING "No top level signals found. Simulator will start without a wave window. If you want to open a wave window go to 'File->New Waveform Configuration' or type 'create_wave_config' in the TCL console."
}
}
# 1. Use 'expr' for the power of 2 calculation
#    We use int() to convert the float result of floor() into an integer for the exponent.
set extracted_acc [expr {2 ** int(floor(log($extracted_acc) / log(2)))}]
puts $extracted_acc
# 2. Use 'expr' for the simulation time calculation
set sim_time [expr {($extracted_acc + $extracted_line*15) * 10}]

puts "Calculated time: $sim_time"

# 3. Run the simulation
#    Note: 'run' is a simulator-specific command (e.g., ModelSim/Vivado), not native Tcl.
run $sim_time ns