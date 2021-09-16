class WaveGenerator(width: Width) extends Module {
	val io = IO(new Bundle {
		val freq = Input(UInt(width))
		val dutyCycle = Input(UInt(width))
		val sawtoothWave = Output(UInt(width))
		val squareWave = Ouput(UInt(width))
		val triangleWave = Ouput(UInt(width))
	}

	val accumulator = Reg(UInt(width))
	accumulator += io.freq

	io.sawtoothWave := accumulator
	io.squareWave := Mux(io.t < io.dutyCycle, 0.U(width), ~0.U(width))
	io.triangleWave := (io.t << 1) ^ io.squareWave
}
