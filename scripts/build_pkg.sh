#!/bin/bash
# Builds a standalone macOS .pkg installer for Dell 1130 Apple Silicon Driver

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PKG_DIR="${ROOT_DIR}/dist"
BUILD_ROOT="${ROOT_DIR}/build/pkg_root"
SCRIPTS_ROOT="${ROOT_DIR}/build/pkg_scripts"

echo "Building driver binary..."
(cd "$ROOT_DIR" && make)

rm -rf "$BUILD_ROOT" "$SCRIPTS_ROOT"
mkdir -p "${BUILD_ROOT}/Library/Printers/Dell/Filters"
mkdir -p "${BUILD_ROOT}/Library/Printers/PPDs/Contents/Resources"
mkdir -p "$SCRIPTS_ROOT" "$PKG_DIR"

# Copy binary
cp "${ROOT_DIR}/bin/rastertoqpdl" "${BUILD_ROOT}/Library/Printers/Dell/Filters/rastertoqpdl"
chmod 755 "${BUILD_ROOT}/Library/Printers/Dell/Filters/rastertoqpdl"

# Gzip and copy PPD
gzip -c "${ROOT_DIR}/ppd/dell1130.ppd" > "${BUILD_ROOT}/Library/Printers/PPDs/Contents/Resources/Dell 1130 Laser Printer.gz"
chmod 644 "${BUILD_ROOT}/Library/Printers/PPDs/Contents/Resources/Dell 1130 Laser Printer.gz"

# Create postinstall script
cat <<'POSTINSTALL_EOF' > "${SCRIPTS_ROOT}/postinstall"
#!/bin/bash
set -e

PPD="/Library/Printers/PPDs/Contents/Resources/Dell 1130 Laser Printer.gz"
USB_URI=$(/usr/libexec/cups/backend/usb 2>/dev/null | grep -i -E "dell.*1130|1130.*laser" | awk '{print $2}' || true)

QUEUE_NAME="Dell_1130"
if [ -z "$USB_URI" ]; then
    USB_URI="usb://Dell/1130%20Laser%20Printer"
fi

lpadmin -x "$QUEUE_NAME" 2>/dev/null || true
lpadmin -p "$QUEUE_NAME" \
    -E \
    -v "$USB_URI" \
    -P "$PPD" \
    -D "Dell 1130 Laser Printer" \
    -L "USB" \
    -o PageSize=Letter

cupsenable "$QUEUE_NAME" 2>/dev/null || true
cupsaccept "$QUEUE_NAME" 2>/dev/null || true

exit 0
POSTINSTALL_EOF
chmod 755 "${SCRIPTS_ROOT}/postinstall"

OUTPUT_PKG="${PKG_DIR}/Dell_1130_Driver_Apple_Silicon.pkg"

echo "Running pkgbuild..."
pkgbuild \
    --root "$BUILD_ROOT" \
    --scripts "$SCRIPTS_ROOT" \
    --identifier "org.openprinting.dell1130" \
    --version "2.0.0" \
    --ownership recommended \
    "$OUTPUT_PKG"

echo ""
echo "Package built successfully: $OUTPUT_PKG"
