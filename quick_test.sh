#!/bin/bash

# Quick test script for debugging bitmap conversion issues

set -e

echo "🔧 Quick TSPL Filter Test"
echo "========================="

# Check if filter exists
if [ ! -f "./rastertotspl" ]; then
    echo "❌ Filter not found, building..."
    make clean && make
fi

# Create a simple test pattern using Python
echo "📝 Creating test pattern..."

python3 << 'EOF'
import struct
import sys

# Create a simple test image: 64x32 pixels with pattern
width = 64
height = 32
bytes_per_line = (width + 7) // 8

print(f"Creating {width}x{height} test pattern...")

# Create CUPS raster header (simplified)
with open('test_pattern.raster', 'wb') as f:
    # CUPS raster magic and basic header
    f.write(b'RaS2')
    f.write(struct.pack('<I', width))      # cupsWidth
    f.write(struct.pack('<I', height))     # cupsHeight  
    f.write(struct.pack('<I', bytes_per_line)) # cupsBytesPerLine
    f.write(struct.pack('<I', 1))          # cupsBitsPerPixel
    f.write(struct.pack('<I', 203))        # HWResolution[0]
    f.write(struct.pack('<I', 203))        # HWResolution[1]
    
    # Write test pattern
    for y in range(height):
        line = bytearray(bytes_per_line)
        for x in range(width):
            # Create a pattern: diagonal lines and borders
            pixel = 0
            if x == 0 or x == width-1 or y == 0 or y == height-1:
                pixel = 1  # Border
            elif (x + y) % 8 == 0:
                pixel = 1  # Diagonal pattern
            elif x % 16 < 8 and y % 16 < 8:
                pixel = 1  # Checkerboard sections
                
            if pixel:
                byte_pos = x // 8
                bit_pos = 7 - (x % 8)
                line[byte_pos] |= (1 << bit_pos)
        
        f.write(line)

print("Test pattern created: test_pattern.raster")
EOF

# Test the filter
echo "🧪 Testing filter conversion..."
./rastertotspl 1 testuser "Test Pattern" 1 "density=8 speed=4" test_pattern.raster > test_output.tspl 2>test_debug.log

echo "📊 Results:"
echo "==========="

# Show TSPL header
echo "TSPL Header:"
head -10 test_output.tspl

echo ""
echo "BITMAP data (first 100 chars):"
grep "BITMAP" test_output.tspl | cut -c1-100

echo ""
echo "File sizes:"
ls -la test_pattern.raster test_output.tspl

echo ""
if [ -s test_debug.log ]; then
    echo "Debug output:"
    cat test_debug.log
else
    echo "✅ No errors in debug log"
fi

echo ""
echo "🔍 Visual check of BITMAP data:"
# Extract just the hex data after BITMAP command
BITMAP_DATA=$(grep "BITMAP" test_output.tspl | sed 's/.*BITMAP 0,0,[0-9]*,[0-9]*,0,//')

# Show first few bytes as binary for verification
echo "First 8 bytes of bitmap data:"
echo "$BITMAP_DATA" | cut -c1-16 | fold -w2 | while read hex; do
    if [ -n "$hex" ]; then
        printf "%s = " "$hex"
        python3 -c "print(format(int('$hex', 16), '08b'))"
    fi
done

echo ""
echo "Expected pattern: borders + diagonals + checkerboard"
echo "In binary: 1 = black dot, 0 = white dot"
echo ""
echo "✅ Test completed! Check test_output.tspl for full TSPL commands"

# Cleanup
rm -f test_pattern.raster debug_bitmap
