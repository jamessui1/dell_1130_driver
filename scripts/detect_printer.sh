#!/bin/bash
set -euo pipefail

echo "=========================================="
echo " Dell 1130 USB Printer Detection Utility  "
echo "=========================================="

echo -n "Checking CUPS USB backend: "
CUPS_USB=$(/usr/libexec/cups/backend/usb 2>&1 || true)
if [ -n "$CUPS_USB" ]; then
    echo "Found!"
    echo "$CUPS_USB"
else
    echo "No USB printers reported by CUPS."
fi

echo ""
echo "Checking IORegistry for printer devices (Interface Class 7 or Dell 1130)..."
IOREG_PRINTER=$(ioreg -p IOUSB -l -w0 | grep -i -E "1130|dell.*print|bInterfaceClass.*7" || true)
if [ -n "$IOREG_PRINTER" ]; then
    echo "Printer detected in IORegistry:"
    echo "$IOREG_PRINTER"
else
    echo "No printer device found in IORegistry."
fi

echo ""
echo "Connected USB devices summary:"
python3 - <<'EOF'
import subprocess, re
try:
    output = subprocess.check_output(["ioreg", "-p", "IOUSB", "-l", "-w0"]).decode("utf-8")
    devices = []
    current = {}
    for line in output.splitlines():
        m_dev = re.search(r"\+-o (.*?) <class", line)
        if m_dev:
            if current:
                devices.append(current)
            current = {"Device": m_dev.group(1).strip()}
        m_prop = re.search(r"\"(USB Product Name|USB Vendor Name|idProduct|idVendor|USB Serial Number)\" = (.*)", line)
        if m_prop and current:
            current[m_prop.group(1)] = m_prop.group(2).strip('"')
    if current:
        devices.append(current)

    for d in devices:
        if "Device" in d and d["Device"] not in ["Root", "AppleT8132USBXHCI@00000000", "AppleT8132USBXHCI@01000000", "AppleUSBXHCITR@20000000"]:
            name = d.get("USB Product Name") or d.get("Device")
            vendor = d.get("USB Vendor Name", "Unknown")
            vid = d.get("idVendor", "")
            pid = d.get("idProduct", "")
            print(f"  - {name} (Vendor: {vendor}, VID: {vid}, PID: {pid})")
except Exception as e:
    print(f"Error parsing devices: {e}")
EOF
