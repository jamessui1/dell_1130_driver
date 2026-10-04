# Dell 1130 Laser Printer Driver for Apple Silicon (macOS arm64)

This project provides an Apple Silicon native CUPS print driver and raster filter for the Dell 1130 monochrome laser printer.

## Background
The Dell 1130 is an OEM printer based on Samsung's print engine (ML-2525 / ML-1910 series) using the Samsung Printer Language / QPDL (Quick Page Description Language v2) protocol with JBIG compression.

Because official legacy drivers for macOS were distributed as x86_64/i386 binaries and have been incompatible with modern macOS on Apple Silicon (arm64), this project provides:
1. Native ARM64 CUPS raster filter (`rastertoqpdl`) with embedded JBIG compression.
2. PPD configuration file tailored for Dell 1130 specifications (600/1200 dpi, Letter/A4/Legal, manual duplex, toner save).
3. Automated installer and detection scripts.

## Repository Structure
- `scripts/`: Diagnostic and installation utilities
  - `detect_printer.sh`: Check USB connectivity and CUPS recognition of the printer
- `src/`: Native driver filter source code
- `ppd/`: CUPS PostScript Printer Description file for Dell 1130
