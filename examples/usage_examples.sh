#!/bin/bash

# Usage examples for CUPS TSPL2 Filter
# These examples show how to use the filter with different options

# Basic printing
echo "=== Basic Examples ==="

# Print a text file
echo "1. Print simple text:"
echo "echo 'Hello, Label!' | lpr -P tspl-printer"

# Print a PDF file
echo "2. Print PDF document:"
echo "lpr -P tspl-printer document.pdf"

# Print an image
echo "3. Print image file:"
echo "lpr -P tspl-printer photo.jpg"

echo ""
echo "=== Advanced Options ==="

# High density printing
echo "4. High density printing (darker):"
echo "lpr -P tspl-printer -o density=12 document.pdf"

# Slow speed for better quality
echo "5. Slow speed printing:"
echo "lpr -P tspl-printer -o speed=2 document.pdf"

# Custom label size
echo "6. Custom label dimensions:"
echo "lpr -P tspl-printer -o label-width=60mm -o label-height=40mm document.pdf"

# Multiple options combined
echo "7. Combined options:"
echo "lpr -P tspl-printer -o density=10 -o speed=3 -o label-width=50mm -o label-height=30mm document.pdf"

echo ""
echo "=== Batch Printing ==="

# Print multiple copies
echo "8. Print multiple copies:"
echo "lpr -P tspl-printer -# 5 document.pdf"

# Print multiple files
echo "9. Print multiple files:"
echo "lpr -P tspl-printer file1.pdf file2.pdf file3.pdf"

echo ""
echo "=== Testing Commands ==="

# Test with different paper sizes
echo "10. Test different paper sizes:"
echo "lpr -P tspl-printer -o media=Label20x15mm small_label.pdf"
echo "lpr -P tspl-printer -o media=Label100x70mm large_label.pdf"

# Debug printing
echo "11. Debug mode (check /var/log/cups/error_log):"
echo "lpr -P tspl-printer -o job-sheets=none,none -o debug document.pdf"

echo ""
echo "=== Printer Management ==="

# Check printer status
echo "12. Check printer status:"
echo "lpstat -p tspl-printer"

# View print queue
echo "13. View print queue:"
echo "lpq -P tspl-printer"

# Cancel jobs
echo "14. Cancel all jobs:"
echo "lprm -P tspl-printer -"

# Enable/disable printer
echo "15. Printer control:"
echo "cupsdisable tspl-printer  # Disable"
echo "cupsenable tspl-printer   # Enable"

echo ""
echo "=== Testing Label Sizes ==="

# Common label sizes with calculations
cat << 'EOF'
16. Common label sizes (width x height in mm):

Small labels:
- 20x15mm: lpr -P tspl-printer -o label-width=20mm -o label-height=15mm
- 25x15mm: lpr -P tspl-printer -o label-width=25mm -o label-height=15mm
- 30x20mm: lpr -P tspl-printer -o label-width=30mm -o label-height=20mm

Medium labels:
- 40x25mm: lpr -P tspl-printer -o label-width=40mm -o label-height=25mm
- 50x30mm: lpr -P tspl-printer -o label-width=50mm -o label-height=30mm
- 60x40mm: lpr -P tspl-printer -o label-width=60mm -o label-height=40mm

Large labels:
- 70x50mm: lpr -P tspl-printer -o label-width=70mm -o label-height=50mm
- 100x70mm: lpr -P tspl-printer -o label-width=100mm -o label-height=70mm

EOF

echo ""
echo "=== Troubleshooting ==="

echo "17. Common troubleshooting commands:"
echo "# Check CUPS logs:"
echo "tail -f /var/log/cups/error_log"
echo ""
echo "# Test filter directly:"
echo "echo 'test' | gs -sDEVICE=cups -r203x203 -g394x236 -o - | ./rastertotspl 1 user title 1 '' > test.tspl"
echo ""
echo "# Check USB connection:"
echo "lsusb | grep -i tsc"
echo ""
echo "# Restart CUPS:"
echo "sudo systemctl restart cups"

echo ""
echo "=== Performance Options ==="

cat << 'EOF'
18. Density settings (1-15):
- 1-5:   Light (for draft prints)
- 6-10:  Medium (standard quality)
- 11-15: Dark (high quality, slower)

19. Speed settings (1-6):
- 1-2: Slow (best quality)
- 3-4: Medium (balanced)
- 5-6: Fast (draft quality)

EOF

echo "20. Example combinations:"
echo "# Draft mode (fast, light):"
echo "lpr -P tspl-printer -o density=5 -o speed=6 document.pdf"
echo ""
echo "# Quality mode (slow, dark):"
echo "lpr -P tspl-printer -o density=12 -o speed=2 document.pdf"
echo ""
echo "# Balanced mode:"
echo "lpr -P tspl-printer -o density=8 -o speed=4 document.pdf"
