
PROJECT   = DMPRO_audio
SYNTH_DIR = logs/synth_$(shell date +"%y%m%d%H%M")
FLASH_DIR = logs/flash_$(shell date +"%y%m%d%H%M")

all:
	-mkdir -p logs
	-mkdir -p $(SYNTHDIR)
	vivado \
		-mode batch \
		-source build.tcl \
		-journal $(SYNTH_DIR)/vivado_build.jou \
		-log $(SYNTH_DIR)/vivado_build.log

program:
	-mkdir -p logs
	-mkdir -p $(FLASH_DIR)
	vivado \
		-mode batch \
		-source program.tcl \
		-journal $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").jou \
		-log $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").log