# Makefile for CUPS TSPL2 Filter
# Compatible with Raspberry Pi 4B and CUPS >= 2.3

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS = -lcups

# Directories
CUPS_FILTER_DIR = /usr/lib/cups/filter
CUPS_BACKEND_DIR = /usr/lib/cups/backend

# Target
TARGET = rastertotspl
SOURCE = rastertotspl.c

# Default target
all: $(TARGET)

# Build the filter
$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(LDFLAGS)

# Clean build artifacts
clean:
	rm -f $(TARGET)

# Install the filter
install: $(TARGET)
	@echo "Installing CUPS filter..."
	sudo cp $(TARGET) $(CUPS_FILTER_DIR)/
	sudo chmod 755 $(CUPS_FILTER_DIR)/$(TARGET)
	sudo chown root:root $(CUPS_FILTER_DIR)/$(TARGET)
	@echo "Filter installed successfully!"
	@echo "Add this line to your PPD file:"
	@echo "*cupsFilter: \"application/vnd.cups-raster 0 rastertotspl\""

# Uninstall the filter
uninstall:
	@echo "Removing CUPS filter..."
	sudo rm -f $(CUPS_FILTER_DIR)/$(TARGET)
	@echo "Filter removed successfully!"

# Test build on different architectures
test-build:
	@echo "Testing build on current architecture..."
	$(MAKE) clean
	$(MAKE) all
	@echo "Build test completed successfully!"

# Debug build
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

# Check CUPS installation
check-cups:
	@echo "Checking CUPS installation..."
	@which cups-config >/dev/null 2>&1 || (echo "CUPS development headers not found. Install with: sudo apt-get install libcups2-dev"; exit 1)
	@echo "CUPS version: $$(cups-config --version)"
	@echo "CUPS filter directory: $(CUPS_FILTER_DIR)"
	@echo "CUPS is properly installed!"

# Show usage information
help:
	@echo "CUPS TSPL2 Filter Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all         - Build the filter (default)"
	@echo "  clean       - Remove build artifacts"
	@echo "  install     - Install filter to CUPS directory (requires sudo)"
	@echo "  uninstall   - Remove filter from CUPS directory (requires sudo)"
	@echo "  debug       - Build with debug symbols"
	@echo "  test-build  - Test build process"
	@echo "  check-cups  - Verify CUPS installation"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make                    # Build the filter"
	@echo "  make install            # Build and install"
	@echo "  make clean all          # Clean build"
	@echo "  sudo make uninstall     # Remove installed filter"

.PHONY: all clean install uninstall test-build debug check-cups help
