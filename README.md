VHDL implementation of the symmetric block cipher AES, as specified in the NIST FIPS 197, respectively NIST SP 800-38A.

Currently supported:

| Mode | Encryption | Decryption | Bitwidth (In & Out) |
| :---: | :---: | :---: | :---: |
| ECB | &#x2611; | &#x274E; | 8, 32 and 128 |
| CBC | &#x2611; | &#x274E; | 8, 32 and 128 |
| CFB | &#x2611; | &#x2611; | 8, 32 and 128 |
| OFB | &#x2611; | &#x2611; | 8, 32 and 128 |
| CTR | &#x274E; | &#x274E; | - |

# Example results

128 bit encryption in ECB mode:

- simulation results:
  - latency: 26 cycles (f. e. 260 ns at 100 MHz clock)
- synthesis results for Zynq 7010:
  - 1259 LUT, 964 FF
  - 0.383 ns worst negative slack at 200 MHz

# Requirements for running the testbenches

- GHDL: https://github.com/tgingold/ghdl
- VUnit: https://github.com/vunit/vunit
- Pycryptodome: https://github.com/Legrandin/pycryptodome

To run the testbenches, simply execute `sim/vunit/run.py`.

# TODO

- Add usage and documentation at least for the interface.
- Add utilization and timing on some FPGA.
- Implement missing encryption modes.
- Implement missing decryption modes.