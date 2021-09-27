tb_fifo: tb_fifo.v ../rtl_modules/fifo.v
	xvlog $^ -O0 -nolog
	xelab -debug typical tb_fifo -s fifo_sim -nolog
	xsim fifo_sim -R -nolog

tb_I2S: tb_I2S_transmitter.v ../rtl_modules/I2S_transmitter.v 
	xvlog $^ -nolog
	xelab -O0 -debug typical tb_I2S_transmitter -s I2S_sim -nolog
	xsim I2S_sim -R -nolog

tb_piso: tb_piso.v ../rtl_modules/shift_registers/piso_register.v 
	xvlog $^ -nolog
	xelab -O0 -debug typical tb_piso -s piso_sim -nolog
	xsim piso_sim -R -nolog

tb_sipo: tb_sipo.sv ../rtl_modules/shift_registers/sipo_register.sv 
	xvlog $^ -nolog -sv
	xelab -O0 -debug typical tb_sipo -s sipo_sim -nolog
	xsim sipo_sim -R -nolog

tb_oscillator: ../rtl_modules/oscillator.sv tb_oscillator.sv 
	xvlog $^ -nolog -sv
	xelab -O0 -debug typical tb_oscillator -s oscillator_sim -nolog
	xsim oscillator_sim -R -nolog

.PHONY:
clean_win:
	rmdir /s /q xsim.dir
	rmdir /s /q .Xil
	del /q *.jou
	del /q *.log
	del /q *.pb
	del /q *.wdb