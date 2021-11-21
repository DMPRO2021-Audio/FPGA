import numpy as np
import sys

if(len(sys.argv) < 2):
    print("Missing args\n1 : Output path\n")
    print("EX: python ./scripts/gen_rom.py ./rtl_modules/memory/wave_rom.v")
    exit(1)
else:
    out_path = sys.argv[1]

luts = [
    "sin_lut.txt",
    "piano_lut.txt",
    "pan_flute_lut.txt",
    "guitar_lut.txt",
]

y = []
for i in range(len(luts)):
    path = "./lookup_tables/" + luts[i]
    print(f"Loading: {path}")
    y_str = np.genfromtxt(path, delimiter=" ", dtype=str)
    for i in range(len(y_str)):
        y.append(int(y_str[i], base=16))

with open(out_path, 'w+') as file:
    
    addr_width = int(np.ceil(np.log2(len(y))))
    data_width = int(np.ceil(np.log2(max(y))))
    
    file.write(f"""`timescale 1ns / 1ps
    module wave_rom (
    input clk,
    input en,
    input [{addr_width-1}:0] addr,
    output reg [{data_width-1}:0] data
    );

    always @(posedge clk) begin
    if (en)
        case(addr)\n""")
    
    file.write("\t\t")
    for i in range(len(y)):
        file.write("\t{addrw}'h{addr:0{addrfw}X}: data <= {dataw}'h{data:0{datafw}X};".format(addrw=addr_width, addrfw=int(np.ceil(addr_width/4)), addr=i, dataw=data_width, datafw=int(np.ceil(data_width/4)), data=y[i]))
    
    file.write("""endcase
    end
    endmodule""")
    
print(f"Generated file {out_path}")