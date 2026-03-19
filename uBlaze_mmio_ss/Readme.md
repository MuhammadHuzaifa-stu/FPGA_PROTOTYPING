
### Generating Clocking Wizard
In order to generate a clocking wizard of 200MHz input to 100MHz output. First place the clocking_wizard IP into ypur project using IP_block_generator then run the following command:

`set_property -dict [list CONFIG.PRIM_IN_FREQ {200.000} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000}] [get_ips *clk_wiz*]`

### NOTE
While generating the microblaze_mcs IP, don't forget to select the `Debug Only` option in microblaze_mcs IP settings otherwise, SDK wouldn't be able to communicate with microblaze_mcs(unable to program).\
 After the bitstream generated, don't open the SDK from vivado directly instead open it from start menue and follow the steps from book in appendix A5 onwards.