
tb_fifo: tb_fifo.v ../rtl_modules/fifo.v
	iverilog -o tb_fifo.out $^
	vvp tb_fifo.out

tb_I2S: ../rtl_modules/I2S_transmitter.v tb_I2S_transmitter.v
	iverilog -o tb_I2S_transmitter.out $^
	vvp tb_I2S_transmitter.out