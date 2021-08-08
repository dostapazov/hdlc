from vunit import VUnit
from glob import glob
import os
from os.path import join, dirname, abspath

def create_test_suite(lib):
    print("Create test suite ")
    save_dir = os.getcwd()
    curr_dir = os.path.dirname( os.path.realpath(__file__) )
    os.chdir(curr_dir);
    
    
    lib.add_source_files("../../tbench_helpers/*.vhd")
    lib.add_source_files("../hdlc_state.vhd")
    lib.add_source_files("hdlc_state.tst.vhd")


    lib.add_source_files("../hdlc_tx_output.vhd")
    lib.add_source_files("hdlc_tx_output.tst.vhd")
    # append test for hdlc_tx_output
    tb1 = lib.entity("tb_hdlc_tx_output")
    tb1.add_config(name="rising-edge:data_with:2", generics=dict(duration = 0));
    tb1.add_config(name="rising-edge:data_with:4", generics=dict(duration = 1));
    tb1.add_config(name="rising-edge:data_with:8", generics=dict(duration = 2));
    tb1.add_config(name="falling-edge:data_with:16", generics=dict(duration = 3,work_edge = "falling"));
    
    lib.add_source_files("../hdlc_tx_data.vhd")
    lib.add_source_files("hdlc_tx_data.tst.vhd")
    
    tb2 = lib.entity("tb_hdlc_tx_data")
    tb2.add_config(name = "output-2-clock", generics=dict(duration = 0))
    tb2.add_config(name = "output-4-clock", generics=dict(duration = 1))
    tb2.add_config(name = "output-8-clock", generics=dict(duration = 2))
    tb2.add_config(name = "output-16-clock", generics=dict(duration = 3))
    
    lib.add_source_files("../hdlc_transmitter.vhd");
    lib.add_source_files("hdlc_transmitter.tst.vhd");
    tb3 = lib.entity("tb_hdlc_transmitter")
    
    os.chdir(save_dir)



def run_test() :
    prj = VUnit.from_argv()
    lib = prj.add_library("work_lib")
    create_test_suite(lib)
    prj.main()

if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "modelsim"
    run_test()

