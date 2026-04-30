import matplotlib.pyplot as plt
import math

n    = 256
bits = 16
# Amplitude for signed 16-bit: -32768 to 32767
amplitude = (2**(bits-1)) - 1

plot_values = []

with open("./uBlaze_mmio_ss/hardware/src/sine_table.txt", "w") as f:
    for i in range(n):
        val = math.sin((2 * math.pi / n) * i) * amplitude
        
        # Round to nearest integer (as requested)
        int_val = int(round(val))
        
        # Convert to 2's complement for 16-bit hex
        # This ensures negative numbers look like 0xFFFF instead of -0x0001
        hex_str = format(int_val & 0xFFFF, '04x')
        
        f.write(f"{hex_str}\n")
        plot_values.append(int_val)

print(f"Successfully generated {n} samples in './uBlaze_mmio_ss/hardware/src/sine_table.txt'")

plt.plot(plot_values)
plt.title(f"Sine Wave LUT ({n} samples, 16-bit)")
plt.xlabel("Sample Index")
plt.ylabel("Amplitude")
plt.grid(True)
plt.show()