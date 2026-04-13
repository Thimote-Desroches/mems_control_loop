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





