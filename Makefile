
all:
	-mkdir -p logs
	vivado \
		-mode batch \
		-source build.tcl \
		-journal logs/vivado_build_$(shell date +"%y%m%d%H%M").jou \
		-log logs/vivado_build_$(shell date +"%y%m%d%H%M").log

program:
	-mkdir -p logs
	vivado \
		-mode batch \
		-source program.tcl \
		-journal logs/vivado_program_$(shell date +"%y%m%d%H%M").jou \
		-log logs/vivado_program_$(shell date +"%y%m%d%H%M").log