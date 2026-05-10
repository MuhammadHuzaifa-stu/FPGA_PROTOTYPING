export CUR_DIR := $(shell realpath .)

VCS_CFLAGS = -full64 -sverilog -debug_access+all -lca -assert svaext +error+100 -kdb
VCS_TS     = -timescale=1ns/1ps
VCS_DEFINE = +define+VCS
VCS_COV    = -cm line+cond+fsm+tgl+branch+assert -cm_dir ./cov_db
VCS_SIM    = +vcs+lic+wait +vcs+dumparrays -assert report=assert_report.txt

SIM_NAME      = i2c_vcs_sim
SIMBUILD_PATH = build
TOP_MODULE    = tb_i2c_core

all: compile elab sim gui_install

gui_install:
	bash -c "install -m 775 <(echo '') opengui"
	scho 'verdi -ssf debug.fsdb' >> opengui

compile:
	mkdir -p $(SIMBUILD_PATH)
	vlogan -f flist -work work $(VCS_CFLAGS) $(VCS_TS) $(VCS_DEFINE) -l vcs_compile.log;

elab:
	vcs work.$(TOP_MODULE) -o $(SIM_NAME) $(VCS_CFLAGS) $(VCS_TS) $(VCS_COV) -l vcs_elab.log;

sim:
	./$(SIM_NAME) $(VCS_SIM) $(VCS_COV) -l vcs_sim.log;

coverage:
	verdi -cov -covdir ./cov_db.vdb &

report:
	urg -dir ./cov_db.vdb -report ./coverage_report -format both -show tests
# coverage_report/
# ├── dashboard.html      ← open in browser
# ├── hierarchy.html      ← per-module breakdown  
# ├── line.html           ← line coverage detail
# ├── branch.html         ← branch coverage detail
# ├── fsm.html            ← FSM state/arc coverage
# ├── toggle.html         ← toggle coverage
# ├── assert.html         ← assertion coverage
# └── urgReport.txt       ← plain text summary

clean:
	@rm -rf AN.DB csrc simv.daidir work.lib++ verdiLog novas.conf debug.fsdb debug.vcd novas.dump.log opengui simv ucli.key vc_hdrs.h vcs_compile.log vcs_elab.log vcs_sim.log $(SIM_NAME) $(SIM_NAME).daidir cov_db coverage_report merged_report $(SIMBUILD_PATH)