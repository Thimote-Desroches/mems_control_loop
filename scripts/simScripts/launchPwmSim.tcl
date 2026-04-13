
catch {close_sim -force}


# Get the absolute path of the directory containing THIS script
set scriptDir [file normalize [file dirname [info script]]]

# If your script is inside /simScripts, go up one level to reach the root
set projectRoot [file normalize [file join $scriptDir "../.."]]

puts "Project Root: $projectRoot"

# Define your paths based on the project root
set fullPath   [file join $projectRoot "scripts/customTCL" "SimScriptPwm.tcl"]
# Normalize paths (fixes slashes for Windows/Tcl compatibility)
set fullPath [file normalize $fullPath]






set_property top tb_PWM_Dynamic [get_filesets sim_1]
set_property generic "" [get_filesets sim_1]
set_property -name {xsim.simulate.custom_tcl} -value $fullPath -objects [get_filesets sim_1]

launch_simulation 
set_property -name {xsim.simulate.custom_tcl} -value {} -objects [get_filesets sim_1]



