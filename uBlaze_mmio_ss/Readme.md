
### Generating Clocking Wizard
In order to generate a clocking wizard of 200MHz input to 100MHz output. First place the clocking_wizard IP into ypur project using IP_block_generator then run the following command:

`set_property -dict [list CONFIG.PRIM_IN_FREQ {200.000} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000}] [get_ips *clk_wiz*]`

### MicroBlaze MCS Debug Configuration
[!IMPORTANT]\
`Enable Debug Support:` When customizing the microblaze_mcs IP, you must set the Enable Debug Support option to `Debug Only`.

Why?\
Without this, the MicroBlaze Debug Module `(MDM)` is not instantiated. The JTAG cable will see the FPGA chip but will fail to find the processor target, resulting in a no targets found error in SDK.