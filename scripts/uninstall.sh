#!/bin/bash
# Uninstaller for Dell 1130 Laser Printer Driver

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "This uninstallation requires administrator privileges."
    echo "Please run: sudo $0"
    exit 1
fi

QUEUE_NAME="Dell_1130"
TARGET_FILTER="/Library/Printers/Dell/Filters/rastertoqpdl"
TARGET_PPD="/Library/Printers/PPDs/Contents/Resources/Dell 1130 Laser Printer.gz"

echo "Removing CUPS queue '${QUEUE_NAME}'..."
lpadmin -x "$QUEUE_NAME" 2>/dev/null || true

echo "Removing driver files..."
rm -f "$TARGET_FILTER"
rm -f "$TARGET_PPD"
rmdir /Library/Printers/Dell/Filters 2>/dev/null || true
rmdir /Library/Printers/Dell 2>/dev/null || true

echo "Dell 1130 driver and queue have been uninstalled."
