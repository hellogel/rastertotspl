/*
 * Debug utility for testing bitmap conversion
 * Helps visualize how pixels are being converted
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_binary(unsigned char byte) {
    for (int i = 7; i >= 0; i--) {
        printf("%d", (byte >> i) & 1);
    }
}

void print_hex_line(unsigned char *data, int width_bytes) {
    for (int i = 0; i < width_bytes; i++) {
        printf("%02X", data[i]);
    }
    printf("\n");
}

void print_visual_line(unsigned char *data, int width_pixels) {
    for (int x = 0; x < width_pixels; x++) {
        int byte_pos = x / 8;
        int bit_pos = 7 - (x % 8);
        int pixel = (data[byte_pos] >> bit_pos) & 1;
        printf("%c", pixel ? '#' : '.');
    }
    printf("\n");
}

int main() {
    printf("TSPL Bitmap Debug Utility\n");
    printf("========================\n\n");
    
    // Test pattern: checkerboard
    int width = 24;  // 3 bytes
    int height = 8;
    int width_bytes = (width + 7) / 8;
    
    printf("Creating %dx%d test pattern (%d bytes per line)\n\n", width, height, width_bytes);
    
    for (int y = 0; y < height; y++) {
        unsigned char line[3] = {0, 0, 0};
        
        // Create checkerboard pattern
        for (int x = 0; x < width; x++) {
            int byte_pos = x / 8;
            int bit_pos = 7 - (x % 8);
            
            // Checkerboard: alternate every 2 pixels
            if ((x / 2 + y / 2) % 2) {
                line[byte_pos] |= (1 << bit_pos);
            }
        }
        
        printf("Line %d: ", y);
        print_hex_line(line, width_bytes);
        printf("        ");
        print_visual_line(line, width);
        printf("        ");
        for (int i = 0; i < width_bytes; i++) {
            print_binary(line[i]);
            printf(" ");
        }
        printf("\n");
    }
    
    printf("\nTSPL BITMAP command would be:\n");
    printf("BITMAP 0,0,%d,%d,0,", width_bytes, height);
    
    // Output all lines as hex
    for (int y = 0; y < height; y++) {
        unsigned char line[3] = {0, 0, 0};
        
        for (int x = 0; x < width; x++) {
            int byte_pos = x / 8;
            int bit_pos = 7 - (x % 8);
            
            if ((x / 2 + y / 2) % 2) {
                line[byte_pos] |= (1 << bit_pos);
            }
        }
        
        for (int i = 0; i < width_bytes; i++) {
            printf("%02X", line[i]);
        }
    }
    printf("\n");
    
    return 0;
}
