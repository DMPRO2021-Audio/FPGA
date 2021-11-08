
PROJECT   = DMPRO_audio
BUILD     = ./design_output
SRC       = ./rtl_modules
TB        = ./testbenches
TEST_OUT  = ./test_output
SCRIPTS   = ./scripts
# Absolute paths because I don't trust Vivado
SRC_DIR   	= $(PWD)/$(SRC)
BUILD_DIR 	= $(PWD)/$(BUILD)
LOGS      	= $(PWD)/logs
CONSTR_DIR	= $(PWD)/constraints
SYNTH_DIR 	= $(PWD)/logs/synth_$(shell date +"%y%m%d%H%M")
FLASH_DIR 	= $(PWD)/logs/flash_$(shell date +"%y%m%d%H%M")
TEMP_DIR  	= $(BUILD_DIR)/tmp


# Timestamps
TS 	= $(BUILD)/.timestamp_

# Compilers
SVC = xvlog --sv
VC 	= xvlog

# Common dependencies to all or most modules
COMMON_DEPS 	= $(TS)structures_pkg

# xvlog workdir, where .sdb files are stored
WORKLIB_NAME 	= work
WORKLIB 		= -work $(WORKLIB_NAME)
WORKLIB_XELAB 	= -L $(WORKLIB_NAME)
INCLUDES 		= --include $(SRC)
SV_DEFINES 		= -d DEBUG

# Optionally set optimisation
ifndef OPT
	OPT=0
endif

ifdef GUI
	GUI=-gui -view $(BUILD)/$@_waves.wcfg
endif

all: synth


## Testbenches ##

$(TS)tb_fifo: $(TB)/tb_fifo.v $(TS)fifo_delay
	xvlog $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_fifovd: $(TB)/tb_fifovd.sv $(TS)fifo_delay
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_clk_downscale: $(TB)/tb_clk_downscale.sv $(TS)clk_downscale
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_dac: $(TB)/tb_dac_transmitter.v $(TS)dac_transmitter
	xvlog $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_sipo: $(TB)/tb_sipo.sv sipo_shift_register
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_oscillator: $(TB)/tb_oscillator.sv $(TS)oscillator $(TS)wave_rom $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_reverb: $(TB)/tb_reverb.sv $(TS)reverberator_core $(TS)mixer $(TS)oscillator $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_mixer: $(TB)/tb_mixer.sv $(TS)mixer $(TS)oscillator $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@

$(TS)tb_pan: $(TB)/tb_pan.sv $(TS)pan $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	touch $@ 


### Module testbenches ###

tb_fifo: $(TS)tb_fifo $(TS)fifo_delay
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 

tb_fifovd: $(TS)tb_fifovd $(TS)fifo_delay
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $(WORKLIB_XELAB) $@_sim -R -nolog 

tb_clk_downscale: $(TS)tb_clk_downscale
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 

tb_dac: $(TS)tb_dac $(TS)dac_transmitter 
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 

tb_piso: tb_piso.v ../rtl_modules/shift_registers/piso_register.v 
	xvlog $^ -nolog
	xelab -O0 -debug typical tb_piso -s piso_sim -nolog
	xsim piso_sim -R -nolog

tb_reverb: $(TS)tb_reverb
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 

tb_sipo: $(TS)tb_sipo
	xelab -O0 -debug typical tb_sipo -s sipo_sim -nolog
	xsim sipo_sim -R -nolog

tb_mixer: $(TS)tb_mixer
	mkdir -p test_output
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 

# ! WORKING EXAMPLE
tb_oscillator: $(TS)tb_oscillator
	-mkdir -p test_output
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 

tb_pan: $(TS)tb_pan
	xelab $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim -nolog
	xsim $@_sim -R -nolog 


### Module targets ###

## Every compilation file needs a TS target ##
# TODO: Make this more automatic!

## Modules ##

$(TS)allpass_filter: $(SRC)/filters/allpass_filter.sv fifo_var_delay
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)clk_wiz: $(SRC)/clk_wiz.v $(COMMON_DEPS)
	xvlog $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)clk_downscale: $(SRC)/clk_downscale.sv
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)comb_filter: $(SRC)/filters/comb_filter.sv fifo_var_delay
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)control_unit: $(SRC)/control_unit.sv $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)dac_transmitter: $(SRC)/dac_transmitter.v $(COMMON_DEPS)
	xvlog $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)fifo_delay: $(SRC)/fifo_delay.sv
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)mixer: $(SRC)/mixer.sv $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)oscillator: $(SRC)/oscillator.sv wave_rom $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog
	@touch $@

$(TS)reverberator_core: $(SRC)/filters/reverberator_core.sv $(TS)clk_downscale $(TS)comb_filter $(TS)allpass_filter
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

$(TS)pan: $(SRC)/pan.sv
	xvlog --sv $(INCLUDES) $(WORKLIB) $< -nolog 
	@touch $@

$(TS)wave_rom: $(SRC)/memory/wave_rom.v
	xvlog $(INCLUDES) $(WORKLIB) $< -nolog 
	@touch $@

$(TS)rom_arbiter: $(SRC)/memory/rom_arbiter.sv $(TS)wave_rom
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
reverberator_core: $(TS)reverberator_core
mixer: $(TS)mixer
pan: $(TS)pan
wave_rom: $(TS)wave_rom
rom_arbiter: $(TS)rom_arbiter

## Top module ##

TOP_DEPS = \
	structures_pkg \
	control_unit \
	spi_slave \
	sipo_shift_register \
	fifo_delay \
	oscillator \
	dac_transmitter \
	mixer \
	reverberator_core \
	rom_arbiter \
	pan

$(TS)top: $(SRC)/top.sv $(TOP_DEPS)
	xvlog --sv $(INCLUDES) $(WORKLIB) $(SV_DEFINES) $< -nolog
	@touch $@

$(TS)tb_top: $(TB)/tb_top.sv $(TOP_DEPS) $(COMMON_DEPS)
	xvlog --sv $(INCLUDES) $(SV_DEFINES) $(WORKLIB) $< --log $(LOGS)/top_xvlog.log 

top: $(TS)top

tb_top: $(TS)tb_top $(TS)top $(TOP_DEPS) $(COMMON_DEPS)
	-mkdir -p $(LOGS)
	-mkdir -p $(TEST_OUT)
	xelab -O$(OPT) $(WORKLIB_XELAB) -debug typical $(WORKLIB_NAME).$@ -s $@_sim --log $(LOGS)/top_xelab.log
	xsim $@_sim -R --log $(LOGS)/xsim.log -wdb $(BUILD)/$@_waves.wdb $(GUI) --ieeewarnings



##########################
### VIVADO TCL TARGETS ###
##########################

TCL_ARGS = \
	$(PROJECT) \
	$(SRC) \
	$(CONSTR_DIR) \
	$(SYNTH_DIR) \
	$(BUILD_DIR) \
	$(SYNTH_ONLY)

# Synthesise and generate bistream
synth:
	-mkdir -p $(BUILD_DIR)
	-mkdir -p $(SYNTH_DIR)
	vivado \
		-mode batch \
		-source scripts/build.tcl \
		-journal $(SYNTH_DIR)/vivado_build.jou \
		-log $(SYNTH_DIR)/vivado_build.log \
		-tclargs $(TCL_ARGS) \
		-tempDir $(TEMP_DIR)

# Flash bitstream to FPGA
flash: $(BUILD_DIR)/program.bit
	-mkdir -p $(FLASH_DIR)
	vivado \
		-mode batch \
		-source scripts/program.tcl \
		-journal $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").jou \
		-log $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").log \
		-tclargs $(TCL_ARGS) \
		-tempDir $(TEMP_DIR)

vivado:
	-mkdir -p $(BUILD_DIR)
	-mkdir -p $(SYNTH_DIR)
	vivado \
		-mode tcl \
		-source scripts/env_setup.tcl \
		-journal $(SYNTH_DIR)/vivado_build.jou \
		-log $(SYNTH_DIR)/vivado_build.log \
		-tclargs $(TCL_ARGS) \
		-tempDir $(TEMP_DIR)

### UTILS ###

# Initialise directories that might have been deleted
init:
	-mkdir -p $(BUILD)
	-mkdir -p $(LOGS)
	-mkdir -p $(TEST_OUT)

help:
	@echo "FPGA makefile"
	@echo "========================================================================================"
	@echo "Usage:"
	@echo "Initialise outputs:	   make init"
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

plot:
	python $(SCRIPTS)/plot_oscillator.py
