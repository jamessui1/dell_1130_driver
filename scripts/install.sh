#!/bin/bash
# Installer for Dell 1130 Laser Printer Driver (Apple Silicon arm64)

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "This installation requires administrator privileges to configure CUPS and /Library/Printers."
    echo "Please run: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "======================================================"
echo " Dell 1130 Laser Printer Driver Installer (macOS ARM64)"
echo "======================================================"

TARGET_FILTER_DIR="/Library/Printers/Dell/Filters"
TARGET_FILTER="${TARGET_FILTER_DIR}/rastertoqpdl"
TARGET_PPD_DIR="/Library/Printers/PPDs/Contents/Resources"
TARGET_PPD="${TARGET_PPD_DIR}/Dell 1130 Laser Printer.gz"

echo "1. Checking/compiling native Apple Silicon driver..."
if [ ! -f "${ROOT_DIR}/bin/rastertoqpdl" ]; then
    echo "Building binary..."
    (cd "$ROOT_DIR" && make clean && make -j4)
fi

echo "2. Installing filter to ${TARGET_FILTER_DIR}..."
mkdir -p "$TARGET_FILTER_DIR"
cp "${ROOT_DIR}/bin/rastertoqpdl" "$TARGET_FILTER"
chown root:wheel "$TARGET_FILTER"
chmod 755 "$TARGET_FILTER"

echo "3. Installing PPD to ${TARGET_PPD_DIR}..."
mkdir -p "$TARGET_PPD_DIR"
gzip -c "${ROOT_DIR}/ppd/dell1130.ppd" > "$TARGET_PPD"
chown root:wheel "$TARGET_PPD"
chmod 644 "$TARGET_PPD"

echo "4. Detecting connected Dell 1130 printer..."
USB_URI=$(/usr/libexec/cups/backend/usb 2>/dev/null | grep -i -E "dell.*1130|1130.*laser" | awk '{print $2}' || true)

QUEUE_NAME="Dell_1130"
if [ -n "$USB_URI" ]; then
    echo "Found USB device: $USB_URI"
else
    echo "Printer not detected currently. Configuring standard USB URI (device can be connected later)..."
    USB_URI="usb://Dell/1130%20Laser%20Printer"
fi

echo "5. Configuring CUPS printer queue '${QUEUE_NAME}'..."
lpadmin -x "$QUEUE_NAME" 2>/dev/null || true
lpadmin -p "$QUEUE_NAME" \
    -E \
    -v "$USB_URI" \
    -P "$TARGET_PPD" \
    -D "Dell 1130 Laser Printer" \
    -L "USB" \
    -o PageSize=Letter

cupsenable "$QUEUE_NAME"
cupsaccept "$QUEUE_NAME"

echo ""
echo "======================================================"
echo " Installation Complete!"
echo " Queue name: ${QUEUE_NAME}"
echo " Status:"
lpstat -p "$QUEUE_NAME" -l
echo "======================================================"
echo "You can now print directly from macOS Print dialogs or via:"
echo "  lpr -P ${QUEUE_NAME} <file>"
