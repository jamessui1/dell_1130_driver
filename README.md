# Dell 1130 Laser Printer Driver for Apple Silicon (macOS ARM64)

Native CUPS print driver and raster filter for the **Dell 1130 monochrome laser printer** on Apple Silicon (M1/M2/M3/M4/etc.) Macs.

## Overview
The Dell 1130 is an OEM printer based on the Samsung ML-2525 / ML-1910 engine. It uses Samsung's proprietary QPDL v3 (Quick Page Description Language) and SPL2 protocols. Legacy drivers provided by Dell and Samsung were only compiled for 32-bit (i386) and 64-bit Intel (x86_64), making them incompatible with modern macOS on Apple Silicon without complex emulation or crashing CUPS filters.

This driver project provides:
- **Native Apple Silicon binary**: Mach-O 64-bit ARM64 raster filter (`rastertoqpdl`) with embedded JBIG85 compression and Algo0x11 support.
- **Optimized PPD**: Conforming Adobe PPD 4.3 specification (`ppd/dell1130.ppd`) for 600 DPI, 1200x600 DPI, manual duplexing, power saving, and toner density controls.
- **Multiple Installation Methods**:
  1. System installation via script (`sudo ./scripts/install.sh`)
  2. Double-clickable macOS Installer Package (`dist/Dell_1130_Driver_Apple_Silicon.pkg`)
  3. Direct CLI print utility without system installation (`./scripts/print_file.sh`)

---

## Quick Start

### 1. Build from Source
```bash
make
```
This compiles `bin/rastertoqpdl` natively using `clang++` for `arm64`.

### 2. Install System Driver
To make the printer available system-wide across all macOS apps (Safari, Preview, Chrome, Word, etc.):

**Option A — Via Terminal:**
```bash
sudo ./scripts/install.sh
```

**Option B — Via macOS Installer GUI:**
```bash
make pkg
open dist/Dell_1130_Driver_Apple_Silicon.pkg
```
Follow the installer prompts and enter your Mac password when requested.

### 3. Print a Test Page
Using the system printer queue:
```bash
lpr -P Dell_1130 test_page.txt
```

Or using the standalone direct USB print utility (no system installation required):
```bash
./scripts/print_file.sh test_page.txt
```

---

## Project Structure
- `src/`: Native C/C++ driver source code
  - `src/jbigkit/`: Embedded ITU-T T.85 JBIG encoder
  - `src/algo0x11.cpp`: Native monochrome run-length dictionary compression
  - `src/qpdl.cpp`: QPDL / SPL protocol packet formatter
  - `src/rastertoqpdl.cpp`: CUPS raster filter entry point
- `ppd/`: PostScript Printer Description file (`dell1130.ppd`)
- `scripts/`:
  - `detect_printer.sh`: Check USB connectivity and IEEE 1284 device info
  - `install.sh`: Install filter and PPD into `/Library/Printers` and register CUPS queue
  - `uninstall.sh`: Remove driver and CUPS queue
  - `build_pkg.sh`: Generate standalone `.pkg` installer
  - `print_file.sh`: Standalone direct-to-USB print runner
- `test_page.txt`: Verification test page

---

## Uninstallation
```bash
sudo ./scripts/uninstall.sh
```
