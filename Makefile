
PROJECT   = DMPRO_audio
BUILD     = ./design_output
SRC       = ./rtl_modules
TB        = ./testbenches
# Absolute paths because I don't trust Vivado
SRC_DIR   = $(PWD)/rtl_modules
BUILD_DIR = $(PWD)/design_output
LOGS      = $(PWD)/logs
CONSTR_DIR= $(PWD)/constraints
SYNTH_DIR = $(PWD)/logs/synth_$(shell date +"%y%m%d%H%M")
FLASH_DIR = $(PWD)logs/flash_$(shell date +"%y%m%d%H%M")
TEMP_DIR  = $(OUTPUT_DIR)/tmp


# Timestamps
TS = $(BUILD)/.timestamp_

# Compilers
SVC = xvlog --sv
VC = xvlog

# Common dependencies to all or most modules
COMMON_DEPS = $(TS)structures_pkg

# xvlog workdir, where .sdb files are stored
WORKLIB_NAME = worklib
WORKLIB = -work $(WORKLIB_NAME)=$(BUILD)
INCLUDES = --include $(SRC)
SV_DEFINES = -d DEBUG=1

# Optionally set optimisation
ifndef OPT
	OPT=0
endif


## Testbenches ##

$(TS)tb_fifo: $(TB)/tb_fifo.v $(TS)fifo_delay
	xvlog $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_fifovd: $(TB)/tb_fifovd.sv $(TS)fifo_delay
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_dac: $(TB)/tb_dac_transmitter.v $(TS)dac_transmitter
	xvlog $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_sipo: $(TB)/tb_sipo.sv sipo_shift_register
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_oscillator: $(TB)/tb_oscillator.sv $(TS)oscillator $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@


### Module testbenches ###

tb_fifo: $(TS)tb_fifo $(TS)fifo_delay
	xelab -L $(WORKLIB_NAME)=$(BUILD) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim -L $(WORKLIB_NAME)=$(BUILD) $@_sim -R -nolog 

tb_fifovd: $(TS)tb_fifovd $(TS)fifo_delay
	xelab -L $(WORKLIB_NAME)=$(BUILD) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim -L $(WORKLIB_NAME)=$(BUILD) $@_sim -R -nolog 

tb_dac: $(TS)tb_dac $(TS)dac_transmitter 
	xelab -L $(WORKLIB_NAME)=$(BUILD) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim -L $(WORKLIB_NAME)=$(BUILD) $@_sim -R -nolog 

tb_piso: tb_piso.v ../rtl_modules/shift_registers/piso_register.v 
	xvlog $^ -nolog
	xelab -O0 -debug typical tb_piso -s piso_sim -nolog
	xsim piso_sim -R -nolog

tb_sipo: $(TS)tb_sipo
	xelab -O0 -debug typical tb_sipo -s sipo_sim -nolog
	xsim sipo_sim -R -nolog

# ! WORKING EXAMPLE
tb_oscillator: $(TS)tb_oscillator
	-mkdir -p test_output
	xelab -L $(WORKLIB_NAME)=$(BUILD) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 

### Module targets ###

## Every compilation file needs a TS target ##
# TODO: Make this more automatic!

## Modules ##

$(TS)allpass_filter: $(SRC)/filters/allpass_filter.sv
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)clk_wiz: $(SRC)/clk_wiz.v $(COMMON_DEPS)
	xvlog $(NCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)comb_filter: $(SRC)/filters/comb_filter.sv
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)control_unit: $(SRC)/control_unit.sv $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)dac_transmitter: $(SRC)/dac_transmitter.v $(COMMON_DEPS)
	xvlog $(NCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)fifo_delay: $(SRC)/fifo_delay.sv
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)oscillator: $(SRC)/oscillator.sv $(COMMON_DEPS)
	xvlog --sv $(NCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)reverberator_core: $(SRC)/filters/reverberator_core.sv 
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)sipo_shift_register: $(SRC)/shift_registers/sipo_register.sv $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)spi_slave: $(SRC)/spi_slave.sv $(TS)sipo_shift_register $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)structures_pkg: $(SRC)/structures_pkg.sv
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog 
	@touch $@

## All modules and their respective compilation unit ##
oscillator: $(TS)oscillator
structures_pkg: $(TS)structures_pkg
dac_transmitter: $(TS)dac_transmitter
sipo_shift_register: $(TS)sipo_shift_register
spi_slave: $(TS)spi_slave
control_unit: $(TS)control_unit
fifo_delay: $(TS)fifo_delay
fifo_var_delay: $(TS)fifo_delay
comb_filter: $(TS)comb_filter
allpass_filter: $(TS)allpass_filter
reverb: $(TS)reverberator_core allpass_filter comb_filter

## Top module ##

TOP_DEPS = \
	structures_pkg \
	control_unit \
	spi_slave \
	sipo_shift_register \
	fifo_delay \
	oscillator \
	dac_transmitter

$(TS)top: $(SRC)/top.sv $(TOP_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $(SV_DEFINES) $< -nolog
	@touch $@

$(TS)tb_top: $(TB)/tb_top.sv $(TOP_DEPS) $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(SV_DEFINES) $(WORKLIB) $< --log $(LOGS)/top_xvlog.log 

top: $(TS)top

tb_top: $(TS)tb_top $(TS)top $(TOP_DEPS) $(COMMON_DEPS)
	-mkdir -p $(LOGS)
	xelab -O$(OPT) -L $(WORKLIB_NAME)=$(BUILD) -debug typical $(WORKLIB_NAME).tb_top -s top_sim --log $(LOGS)/top_xelab.log
	xsim top_sim -R --log ../logs/xsim.log --ieeewarnings



##########################
### VIVADO TCL TARGETS ###
##########################

TCL_ARGS = \
	$(PROJECT) \
	$(SRC) \
	$(CONSTR_DIR) \
	$(SYNTH_DIR) \
	$(OUTPUT_DIR) \
	$(SYNTH_ONLY)

# Synthesise and generate bistream
synth:
	-mkdir -p $(OUTPUT_DIR)
	-mkdir -p $(SYNTH_DIR)
	vivado \
		-mode batch \
		-source scripts/build.tcl \
		-journal $(SYNTH_DIR)/vivado_build.jou \
		-log $(SYNTH_DIR)/vivado_build.log \
		-tclargs $(TCL_ARGS) \
		-tempDir $(TEMP_DIR)

# Flash bitstream to FPGA
flash: $(OUTPUT_DIR)/program.bit
	-mkdir -p $(FLASH_DIR)
	vivado \
		-mode batch \
		-source scripts/program.tcl \
		-journal $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").jou \
		-log $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").log \
		-tclargs $(TCL_ARGS) \
		-tempDir $(TEMP_DIR)


### UTILS ###

# Initialise directories that might have been deleted
init:
	-mkdir -p $(BUILD)
	-mkdir -p $(LOGS)

help:
	@echo "FPGA makefile"
	@echo "========================================================================================"
	@echo "Usage:"
	@echo "Synthesise:             make synth"
	@echo "Flash to FPGA:          make flash"
	@echo "Build top:              make top"
	@echo "Build testbench:        make tb_<module>"
	@echo "Build single module:    make $(TS)<module>"
	@echo "========================================================================================"
	@echo "OPT=[0-3]               Set optimization level (OPT='$(OPT)')"

clean:
	-rm -r xsim.dir
	-rm -r .Xil
	-rm -r test_output
	-rm *.jou
	-rm *.log
	-rm *.pb
	-rm *.wdb
	-rm *.html
	-rm design_output/*

purge: clean
	-rm -rf $(BUILD) $(LOGS) usage_statistics*

