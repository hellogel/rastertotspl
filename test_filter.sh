#!/bin/bash

# Test script for CUPS TSPL2 Filter
# This script creates test raster data and verifies filter output

set -e

FILTER="./rastertotspl"
TEST_DIR="test_output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if filter exists
check_filter() {
    print_status "Checking if filter exists..."
    if [ ! -f "$FILTER" ]; then
        print_error "Filter not found. Run 'make' first."
        exit 1
    fi
    print_status "Filter found: $FILTER"
}

# Create test directory
setup_test_dir() {
    print_status "Setting up test directory..."
    mkdir -p "$TEST_DIR"
}

# Create a simple test raster file using ImageMagick/GraphicsMagick
create_test_raster() {
    local name="$1"
    local width="$2"
    local height="$3"
    local dpi="$4"
    
    print_status "Creating test raster: $name (${width}x${height} @ ${dpi}dpi)"
    
    # Create a simple test pattern with ImageMagick
    if command -v convert >/dev/null 2>&1; then
        # Create test image with text and pattern
        convert -size ${width}x${height} xc:white \
                -font DejaVu-Sans -pointsize 24 -fill black \
                -gravity center -annotate +0-20 "TEST LABEL" \
                -gravity center -annotate +0+20 "$name" \
                -density $dpi \
                "$TEST_DIR/${name}.png"
        
        # Convert to raster using Ghostscript
        gs -sDEVICE=cups -r${dpi}x${dpi} -g${width}x${height} \
           -sOutputFile="$TEST_DIR/${name}.raster" \
           -f "$TEST_DIR/${name}.png" >/dev/null 2>&1
           
    elif command -v gm >/dev/null 2>&1; then
        # Use GraphicsMagick as alternative
        gm convert -size ${width}x${height} xc:white \
                   -font DejaVu-Sans -pointsize 24 -fill black \
                   -gravity center -annotate +0-20 "TEST LABEL" \
                   -gravity center -annotate +0+20 "$name" \
                   -density $dpi \
                   "$TEST_DIR/${name}.png"
                   
        gs -sDEVICE=cups -r${dpi}x${dpi} -g${width}x${height} \
           -sOutputFile="$TEST_DIR/${name}.raster" \
           -f "$TEST_DIR/${name}.png" >/dev/null 2>&1
    else
        print_warning "ImageMagick/GraphicsMagick not found, creating simple binary raster"
        create_simple_raster "$name" "$width" "$height"
    fi
}

# Create a simple binary raster file manually
create_simple_raster() {
    local name="$1"
    local width="$2"
    local height="$3"
    
    print_status "Creating simple binary raster for $name"
    
    # This is a simplified approach - in real scenarios you'd use proper CUPS raster format
    # For now, we'll create a pattern that the filter can read
    python3 -c "
import struct
import sys

# CUPS raster header (simplified)
width = $width
height = $height
bytes_per_line = (width + 7) // 8

# Create a simple pattern
with open('$TEST_DIR/${name}.raster', 'wb') as f:
    # Write CUPS raster header (minimal)
    f.write(b'RaS2')  # Magic number
    f.write(struct.pack('<I', width))
    f.write(struct.pack('<I', height))
    f.write(struct.pack('<I', bytes_per_line))
    f.write(struct.pack('<I', 1))  # bits per pixel
    f.write(struct.pack('<I', 203))  # DPI X
    f.write(struct.pack('<I', 203))  # DPI Y
    
    # Write pattern data (checkerboard)
    for y in range(height):
        line = bytearray(bytes_per_line)
        for x in range(width):
            if (x // 8 + y // 8) % 2:
                byte_pos = x // 8
                bit_pos = 7 - (x % 8)
                line[byte_pos] |= (1 << bit_pos)
        f.write(line)
print('Created simple raster file')
"
}

# Test the filter with different parameters
test_filter() {
    local test_name="$1"
    local raster_file="$2"
    local options="$3"
    
    print_status "Testing filter: $test_name"
    
    if [ ! -f "$raster_file" ]; then
        print_error "Raster file not found: $raster_file"
        return 1
    fi
    
    local output_file="$TEST_DIR/${test_name}.tspl"
    
    # Run the filter
    echo "Running: $FILTER 1 testuser 'Test Job' 1 '$options' '$raster_file'"
    if $FILTER 1 testuser "Test Job" 1 "$options" "$raster_file" > "$output_file" 2>"$TEST_DIR/${test_name}.log"; then
        print_status "Filter completed successfully"
        
        # Check output
        if [ -s "$output_file" ]; then
            print_status "Output file created: $output_file ($(wc -c < "$output_file") bytes)"
            
            # Verify TSPL commands
            if grep -q "SIZE" "$output_file" && \
               grep -q "DENSITY" "$output_file" && \
               grep -q "BITMAP" "$output_file" && \
               grep -q "PRINT" "$output_file"; then
                print_status "✓ TSPL commands found in output"
            else
                print_warning "⚠ Some TSPL commands missing"
            fi
            
            # Show first few lines
            echo "First 10 lines of output:"
            head -10 "$output_file" | sed 's/^/  /'
            
        else
            print_error "Output file is empty"
            return 1
        fi
    else
        print_error "Filter failed"
        echo "Error log:"
        cat "$TEST_DIR/${test_name}.log" | sed 's/^/  /'
        return 1
    fi
}

# Run all tests
run_tests() {
    print_status "Starting filter tests..."
    
    # Test 1: Basic 50x30mm label
    create_test_raster "label_50x30" 394 236 203
    test_filter "basic_50x30" "$TEST_DIR/label_50x30.raster" ""
    
    # Test 2: Different density
    test_filter "high_density" "$TEST_DIR/label_50x30.raster" "density=12"
    
    # Test 3: Different speed
    test_filter "slow_speed" "$TEST_DIR/label_50x30.raster" "speed=2"
    
    # Test 4: Custom label size
    test_filter "custom_size" "$TEST_DIR/label_50x30.raster" "label-width=60mm label-height=40mm"
    
    # Test 5: Combined options
    test_filter "combined_options" "$TEST_DIR/label_50x30.raster" "density=10 speed=3 label-width=50mm label-height=30mm"
    
    print_status "All tests completed!"
}

# Generate report
generate_report() {
    print_status "Generating test report..."
    
    local report_file="$TEST_DIR/test_report.txt"
    
    {
        echo "CUPS TSPL2 Filter Test Report"
        echo "============================="
        echo "Generated: $(date)"
        echo "Filter: $FILTER"
        echo ""
        
        echo "Test Files:"
        ls -la "$TEST_DIR"/*.tspl 2>/dev/null || echo "No TSPL files found"
        echo ""
        
        echo "Sample Output (basic_50x30.tspl):"
        if [ -f "$TEST_DIR/basic_50x30.tspl" ]; then
            head -20 "$TEST_DIR/basic_50x30.tspl"
        else
            echo "File not found"
        fi
        
    } > "$report_file"
    
    print_status "Report saved to: $report_file"
}

# Main execution
main() {
    echo "CUPS TSPL2 Filter Test Suite"
    echo "============================"
    echo ""
    
    check_filter
    setup_test_dir
    run_tests
    generate_report
    
    echo ""
    print_status "Test suite completed. Check $TEST_DIR/ for results."
}

# Handle command line arguments
case "${1:-}" in
    "clean")
        print_status "Cleaning test directory..."
        rm -rf "$TEST_DIR"
        print_status "Test directory cleaned."
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [clean|help]"
        echo ""
        echo "Commands:"
        echo "  (no args)  Run all tests"
        echo "  clean      Remove test output directory"
        echo "  help       Show this help message"
        ;;
    *)
        main
        ;;
esac
