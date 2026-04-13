file mkdir ../pynqZ2VivadoProject
cd ../pynqZ2VivadoProject

xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]

#Creating and setting the correct board
create_project memsControlLoop -part xc7z020clg400-1
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]

#Add all files
set vhdl_files [glob ../hdl/modules/*.vhd]
foreach file $vhdl_files {
    add_files $file
}
# Add all testbench files
set vhdl_files [glob ../sim/tb/*.vhd]
foreach file $vhdl_files {
	add_files -fileset sim_1 -norecurse -scan_for_includes $file
}







add_files -fileset constrs_1 -norecurse ../constraints/PYNQ-Z2_loops_final.xdc



# Source the block design script
source ../scripts/blockDesign/averageBlockDesign_wClock.tcl

# 1. Find the block design file dynamically
set bd_file [get_files *averageBlockDesign_wClock.bd]

# 2. Generate the wrapper and save its path to a variable
set wrapper_path [make_wrapper -files $bd_file -top]

# 3. Add the dynamically generated wrapper file to the project
add_files -norecurse $wrapper_path

# 4. Set the wrapper as the top-level module (highly recommended)
set_property top averageBlockDesign_wClock_wrapper [current_fileset]

# 5. Update compile order
update_compile_order -fileset sources_1