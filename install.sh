#!/bin/bash

# Installation script for CUPS TSPL2 Filter
# Designed for Raspberry Pi 4B with CUPS >= 2.3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FILTER_NAME="rastertotspl"
CUPS_FILTER_DIR="/usr/lib/cups/filter"
PPD_DIR="/usr/share/cups/model"
PPD_FILE="tspl-printer.ppd"

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

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root for installation
check_permissions() {
    if [ "$EUID" -ne 0 ] && [ "$1" == "install" ]; then
        print_error "Installation requires root privileges. Use sudo."
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_header "Checking system requirements..."
    
    # Check for CUPS
    if ! command -v cups-config >/dev/null 2>&1; then
        print_error "CUPS development headers not found."
        print_status "Install with: sudo apt-get install libcups2-dev"
        exit 1
    fi
    
    local cups_version=$(cups-config --version)
    print_status "CUPS version: $cups_version"
    
    # Check for GCC
    if ! command -v gcc >/dev/null 2>&1; then
        print_error "GCC compiler not found."
        print_status "Install with: sudo apt-get install build-essential"
        exit 1
    fi
    
    print_status "GCC version: $(gcc --version | head -n1)"
    
    # Check for make
    if ! command -v make >/dev/null 2>&1; then
        print_error "Make utility not found."
        print_status "Install with: sudo apt-get install build-essential"
        exit 1
    fi
    
    print_status "All requirements satisfied!"
}

# Install dependencies
install_dependencies() {
    print_header "Installing dependencies..."
    
    apt-get update
    apt-get install -y build-essential libcups2-dev cups-filters
    
    print_status "Dependencies installed successfully!"
}

# Build the filter
build_filter() {
    print_header "Building TSPL2 filter..."
    
    if [ ! -f "Makefile" ]; then
        print_error "Makefile not found. Are you in the correct directory?"
        exit 1
    fi
    
    # Clean previous builds
    make clean >/dev/null 2>&1 || true
    
    # Build the filter
    if make; then
        print_status "Filter built successfully!"
    else
        print_error "Build failed!"
        exit 1
    fi
    
    # Verify the binary
    if [ ! -f "$FILTER_NAME" ]; then
        print_error "Filter binary not found after build!"
        exit 1
    fi
    
    print_status "Filter binary verified: $FILTER_NAME"
}

# Install the filter
install_filter() {
    print_header "Installing TSPL2 filter..."
    
    # Create CUPS filter directory if it doesn't exist
    mkdir -p "$CUPS_FILTER_DIR"
    
    # Copy filter binary
    cp "$FILTER_NAME" "$CUPS_FILTER_DIR/"
    chmod 755 "$CUPS_FILTER_DIR/$FILTER_NAME"
    chown root:root "$CUPS_FILTER_DIR/$FILTER_NAME"
    
    print_status "Filter installed to: $CUPS_FILTER_DIR/$FILTER_NAME"
    
    # Install PPD file
    if [ -f "$PPD_FILE" ]; then
        mkdir -p "$PPD_DIR"
        cp "$PPD_FILE" "$PPD_DIR/"
        chmod 644 "$PPD_DIR/$PPD_FILE"
        chown root:root "$PPD_DIR/$PPD_FILE"
        print_status "PPD file installed to: $PPD_DIR/$PPD_FILE"
    else
        print_warning "PPD file not found. You'll need to configure the printer manually."
    fi
}

# Configure CUPS
configure_cups() {
    print_header "Configuring CUPS..."
    
    # Restart CUPS service
    systemctl restart cups
    print_status "CUPS service restarted"
    
    # Enable CUPS service
    systemctl enable cups
    print_status "CUPS service enabled"
    
    print_status "CUPS configuration completed!"
}

# Show post-installation instructions
show_instructions() {
    print_header "Installation completed successfully!"
    
    echo ""
    echo "Next steps:"
    echo "==========="
    echo ""
    echo "1. Add your TSPL printer:"
    echo "   - Open web browser: http://localhost:631"
    echo "   - Go to Administration > Add Printer"
    echo "   - Select your USB printer"
    echo "   - Choose 'Generic TSPL Label Printer' from the model list"
    echo ""
    echo "2. Or use command line:"
    echo "   sudo lpadmin -p tspl-printer -v usb://... -m tspl-printer.ppd -E"
    echo ""
    echo "3. Test printing:"
    echo "   echo 'Test Label' | lpr -P tspl-printer"
    echo ""
    echo "4. Print with options:"
    echo "   lpr -P tspl-printer -o density=10 -o speed=3 document.pdf"
    echo ""
    echo "Available options:"
    echo "  -o density=<1-15>     Set print density"
    echo "  -o speed=<1-6>        Set print speed"
    echo "  -o label-width=XXmm   Set label width"
    echo "  -o label-height=YYmm  Set label height"
    echo ""
    echo "For troubleshooting, check: /var/log/cups/error_log"
}

# Uninstall the filter
uninstall_filter() {
    print_header "Uninstalling TSPL2 filter..."
    
    # Remove filter binary
    if [ -f "$CUPS_FILTER_DIR/$FILTER_NAME" ]; then
        rm -f "$CUPS_FILTER_DIR/$FILTER_NAME"
        print_status "Filter removed from: $CUPS_FILTER_DIR/$FILTER_NAME"
    else
        print_warning "Filter not found in: $CUPS_FILTER_DIR/$FILTER_NAME"
    fi
    
    # Remove PPD file
    if [ -f "$PPD_DIR/$PPD_FILE" ]; then
        rm -f "$PPD_DIR/$PPD_FILE"
        print_status "PPD file removed from: $PPD_DIR/$PPD_FILE"
    else
        print_warning "PPD file not found in: $PPD_DIR/$PPD_FILE"
    fi
    
    # Restart CUPS
    systemctl restart cups
    print_status "CUPS service restarted"
    
    print_status "Uninstallation completed!"
}

# Run tests
run_tests() {
    print_header "Running tests..."
    
    if [ ! -f "test_filter.sh" ]; then
        print_error "Test script not found!"
        exit 1
    fi
    
    ./test_filter.sh
    print_status "Tests completed!"
}

# Show usage information
show_usage() {
    echo "CUPS TSPL2 Filter Installation Script"
    echo "====================================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install     - Full installation (requires sudo)"
    echo "  uninstall   - Remove filter and PPD (requires sudo)"
    echo "  build       - Build filter only"
    echo "  test        - Run tests"
    echo "  deps        - Install dependencies only (requires sudo)"
    echo "  check       - Check system requirements"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0 install    # Full installation"
    echo "  $0 build           # Build only"
    echo "  $0 test            # Run tests"
    echo "  sudo $0 uninstall  # Remove installation"
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "install")
            check_permissions "$command"
            check_requirements
            install_dependencies
            build_filter
            install_filter
            configure_cups
            show_instructions
            ;;
        "uninstall")
            check_permissions "$command"
            uninstall_filter
            ;;
        "build")
            check_requirements
            build_filter
            ;;
        "test")
            run_tests
            ;;
        "deps")
            check_permissions "$command"
            install_dependencies
            ;;
        "check")
            check_requirements
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
