
SRC = ../rtl_modules

INCLUDES = --include $(SRC)

ifndef OPT
	OPT=0
endif

tb_fifo: tb_fifo.v ../rtl_modules/fifo_delay.sv
	xvlog $^ -O0 -nolog
	xelab -debug typical tb_fifo -s fifo_sim -nolog
	xsim fifo_sim -R -nolog 

tb_fifovd: tb_fifovd.sv ../rtl_modules/fifo_delay.sv
	xvlog --sv $^ -nolog
	xelab -O$(OPT) -debug typical tb_fifovd -s fifovd_sim -nolog
	xsim fifovd_sim -R -nolog -unbuffered

tb_dac: tb_dac_transmitter.v ../rtl_modules/dac_transmitter.v 
	xvlog $^ -nolog
	xelab -O0 -debug typical tb_dac_transmitter -s dac_sim -nolog
	xsim dac_sim -R -nolog

tb_piso: tb_piso.v ../rtl_modules/shift_registers/piso_register.v 
	xvlog $^ -nolog
	xelab -O0 -debug typical tb_piso -s piso_sim -nolog
	xsim piso_sim -R -nolog

tb_sipo: tb_sipo.sv ../rtl_modules/shift_registers/sipo_register.sv 
	xvlog $^ -nolog -sv
	xelab -O0 -debug typical tb_sipo -s sipo_sim -nolog
	xsim sipo_sim -R -nolog

tb_oscillator: ../rtl_modules/structures_pkg.sv ../rtl_modules/oscillator.sv tb_oscillator.sv 
	xvlog $^ -nolog -sv
	xelab -O0 -debug typical tb_oscillator -s oscillator_sim -nolog
	mkdir -p test_output
	xsim oscillator_sim -R -nolog

tb_mixer: tb_mixer.sv ../rtl_modules/mixer.sv ../rtl_modules/structures_pkg.sv ../rtl_modules/oscillator.sv
	xvlog $^ -nolog -sv
	xelab -O0 -debug typical tb_mixer -s mixer_sim -nolog
	xsim mixer_sim -R -nolog

TOP_SRC = \
	$(SRC)/structures_pkg.sv \
	$(SRC)/control_unit.sv \
	$(SRC)/spi_slave.sv \
	$(SRC)/shift_registers/sipo_register.sv \
	$(SRC)/fifo_delay.sv \
	$(SRC)/top.sv

TOP_SDB = $(patsubst ../rtl_modules/%.sv, xsim.dir/work/%.sdb, $(TOP_SRC))

tb_top: tb_top.sv $(TOP_SRC)
	echo $(TOP_SDB)
	xvlog --sv $(INCLUDES) $^ -d DEBUG=1 --log ../logs/xvlog.log 
	xelab -O$(OPT) -debug typical tb_top -s top_sim --log ../logs/xelab.log
	xsim top_sim -R --log ../logs/xsim.log --ieeewarnings

tb_control_unit: $(SRC)/structures_pkg.sv $(SRC)/control_unit.sv
	xvlog --sv $^ -d DEBUG=1 --log ../logs/xvlog.log
	# xelab -O$(OPT) -debug typical control_unit -s control_unit_sim -nolog
	# xsim  control_unit_sim -R -nolog

help:
	-echo "Testbenches makefile"
	-echo "========================================================="
	-echo "OPT=[0-3]	Set optimization level (OPT='$(OPT)')"

.PHONY:
clean_win:
	rmdir /s /q xsim.dir
	rmdir /s /q .Xil
	del /q *.jou
	del /q *.log
	del /q *.pb
	del /q *.wdb

clean:
	-rm -r xsim.dir
	-rm -r .Xil
	-rm -r test_output
	-rm *.jou
	-rm *.log
	-rm *.pb
	-rm *.wdb
