#!/bin/bash
# Standalone print utility for Dell 1130 Laser Printer (Apple Silicon)
# Sends a print job directly to the printer without requiring system installation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <file-to-print> [copies] [options]"
    echo "Example: $0 test.pdf"
    exit 1
fi

INPUT_FILE="$1"
COPIES="${2:-1}"
OPTIONS="${3:-}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

FILTER_BIN="${ROOT_DIR}/bin/rastertoqpdl"
PPD_FILE="${ROOT_DIR}/ppd/dell1130.ppd"

if [ ! -x "$FILTER_BIN" ]; then
    echo "Building rastertoqpdl filter..."
    (cd "$ROOT_DIR" && make)
fi

echo "Detecting Dell 1130 USB URI..."
USB_URI=$(/usr/libexec/cups/backend/usb 2>/dev/null | grep -i -E "dell.*1130|1130.*laser" | awk '{print $2}' || true)

if [ -z "$USB_URI" ]; then
    echo "Error: Dell 1130 printer not found on USB."
    echo "Make sure the printer is turned on and connected."
    exit 1
fi

echo "Found printer: $USB_URI"

TMP_DIR=$(mktemp -d /tmp/dell1130_print.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

PRN_FILE="${TMP_DIR}/job.prn"
JOB_TITLE="$(basename "$INPUT_FILE")"

echo "Rasterizing and encoding job using Apple Silicon native rastertoqpdl..."
PPD="$PPD_FILE" /usr/sbin/cupsfilter -p "$PPD_FILE" -m application/vnd.cups-raster "$INPUT_FILE" 2>/dev/null \
    | PPD="$PPD_FILE" "$FILTER_BIN" 1 "$USER" "$JOB_TITLE" "$COPIES" "$OPTIONS" > "$PRN_FILE"

FILE_SIZE=$(stat -f%z "$PRN_FILE" 2>/dev/null || echo "0")
echo "Generated QPDL print stream ($FILE_SIZE bytes)."

echo "Sending data to printer via USB..."
DEVICE_URI="$USB_URI" /usr/libexec/cups/backend/usb 1 "$USER" "$JOB_TITLE" "$COPIES" "$OPTIONS" "$PRN_FILE"

echo "Print job sent successfully!"
