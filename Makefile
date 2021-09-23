
PROJECT   = DMPRO_audio
OUTPUT_DIR= $(PWD)/design_output
SYNTH_DIR = $(PWD)/logs/synth_$(shell date +"%y%m%d%H%M")
FLASH_DIR = $(PWD)logs/flash_$(shell date +"%y%m%d%H%M")
TEMP_DIR  = $(OUTPUT_DIR)/tmp

TCL_ARGS = \
	$(PROJECT) \
	$(SYNTH_DIR) \
	$(OUTPUT_DIR)

all:
	-mkdir -p $(OUTPUT_DIR)
	-mkdir -p $(SYNTH_DIR)
	vivado \
		-mode batch \
		-source build.tcl \
		-journal $(SYNTH_DIR)/vivado_build.jou \
		-log $(SYNTH_DIR)/vivado_build.log \
		-tclargs $(TCL_ARGS) \
		-tempDir $(TEMP_DIR)

flash: $(OUTPUT_DIR)/program.bit
	-mkdir -p $(FLASH_DIR)
	vivado \
		-mode batch \
		-source program.tcl \
		-journal $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").jou \
		-log $(FLASH_DIR)/vivado_program_$(shell date +"%y%m%d%H%M").log \
		-tclargs $(TCL_ARGS) \
		-tempDir $(TEMP_DIR)
	
purge:
	-rm -rf design_output logs usage_statistics*
