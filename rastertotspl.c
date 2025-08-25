/*
 * CUPS TSPL2 Filter
 * Converts CUPS raster data to TSPL2 commands for label printers
 *
 * Compatible with EZPOS L4-W and other Chinese TSPL clone printers
 *
 * License: MIT
 * Author: Generated for Raspberry Pi 4B with CUPS >= 2.3
 */

#include <cups/cups.h>
#include <cups/raster.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

/* Default values for TSPL commands */
#define DEFAULT_DENSITY 8
#define DEFAULT_SPEED 4
#define DEFAULT_GAP 2
#define MM_PER_INCH 25.4

/* Function prototypes */
static void print_usage(void);
static int parse_options(int num_options, cups_option_t *options,
                         int *density, int *speed, double *label_width,
                         double *label_height, int *rotate);
static void convert_raster_to_tspl(cups_raster_t *ras, FILE *output,
                                   int density, int speed,
                                   double label_width, double label_height);
static void output_tspl_header(FILE *output, double width_mm, double height_mm,
                               int density, int speed);
static void output_bitmap_data(FILE *output, cups_page_header2_t *header,
                               unsigned char *line_buffer, cups_raster_t *ras);

int main(int argc, char *argv[])
{
    cups_raster_t *ras;
    FILE *output;
    int num_options;
    cups_option_t *options;
    int density = DEFAULT_DENSITY;
    int speed = DEFAULT_SPEED;
    double label_width = 0.0;
    double label_height = 0.0;
    int rotate = 0;

    /* Check command line arguments */
    if (argc < 6 || argc > 7)
    {
        print_usage();
        return 1;
    }

    /* Parse options from command line */
    num_options = cupsParseOptions(argv[5], 0, &options);
    parse_options(num_options, options, &density, &speed,
                  &label_width, &label_height, &rotate);

    /* Open raster stream */
    if (argc == 7)
    {
        /* Read from file */
        int fd = open(argv[6], O_RDONLY);
        if (fd < 0)
        {
            fprintf(stderr, "ERROR: Unable to open raster file %s: %s\n",
                    argv[6], strerror(errno));
            return 1;
        }
        ras = cupsRasterOpen(fd, CUPS_RASTER_READ);
    }
    else
    {
        /* Read from stdin */
        ras = cupsRasterOpen(0, CUPS_RASTER_READ);
    }

    if (!ras)
    {
        fprintf(stderr, "ERROR: Unable to open raster stream\n");
        return 1;
    }

    /* Output to stdout */
    output = stdout;

    /* Convert raster to TSPL */
    convert_raster_to_tspl(ras, output, density, speed,
                           label_width, label_height);

    /* Cleanup */
    cupsRasterClose(ras);
    cupsFreeOptions(num_options, options);

    return 0;
}

static void print_usage(void)
{
    fprintf(stderr, "Usage: rastertotspl job-id user title copies options [file]\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -o density=<1-15>     Set print density (default: %d)\n", DEFAULT_DENSITY);
    fprintf(stderr, "  -o speed=<1-6>        Set print speed (default: %d)\n", DEFAULT_SPEED);
    fprintf(stderr, "  -o label-width=XXmm   Set label width in mm\n");
    fprintf(stderr, "  -o label-height=YYmm  Set label height in mm\n");
    fprintf(stderr, "  -o rotate=90          Rotate output 90 degrees\n");
}

static int parse_options(int num_options, cups_option_t *options,
                         int *density, int *speed, double *label_width,
                         double *label_height, int *rotate)
{
    const char *val;

    /* Parse density option */
    if ((val = cupsGetOption("density", num_options, options)) != NULL)
    {
        int d = atoi(val);
        if (d >= 1 && d <= 15)
        {
            *density = d;
        }
        else
        {
            fprintf(stderr, "WARNING: Invalid density %d, using default %d\n",
                    d, DEFAULT_DENSITY);
        }
    }

    /* Parse speed option */
    if ((val = cupsGetOption("speed", num_options, options)) != NULL)
    {
        int s = atoi(val);
        if (s >= 1 && s <= 6)
        {
            *speed = s;
        }
        else
        {
            fprintf(stderr, "WARNING: Invalid speed %d, using default %d\n",
                    s, DEFAULT_SPEED);
        }
    }

    /* Parse label dimensions */
    if ((val = cupsGetOption("label-width", num_options, options)) != NULL)
    {
        *label_width = strtod(val, NULL);
    }

    if ((val = cupsGetOption("label-height", num_options, options)) != NULL)
    {
        *label_height = strtod(val, NULL);
    }

    /* Parse rotation */
    if ((val = cupsGetOption("rotate", num_options, options)) != NULL)
    {
        *rotate = atoi(val);
    }

    return 0;
}

static void convert_raster_to_tspl(cups_raster_t *ras, FILE *output,
                                   int density, int speed,
                                   double label_width, double label_height)
{
    cups_page_header2_t header;
    unsigned char *line_buffer;
    int page = 0;

    /* Process each page */
    while (cupsRasterReadHeader2(ras, &header))
    {
        page++;

        fprintf(stderr, "DEBUG: Processing page %d\n", page);
        fprintf(stderr, "DEBUG: Page size: %ux%u pixels\n",
                header.cupsWidth, header.cupsHeight);
        fprintf(stderr, "DEBUG: Resolution: %ux%u dpi\n",
                header.HWResolution[0], header.HWResolution[1]);
        fprintf(stderr, "DEBUG: Bits per pixel: %u\n", header.cupsBitsPerPixel);
        fprintf(stderr, "DEBUG: Bytes per line: %u\n", header.cupsBytesPerLine);

        /* Calculate label dimensions if not specified */
        double width_mm, height_mm;
        if (label_width > 0)
        {
            width_mm = label_width;
        }
        else
        {
            width_mm = header.cupsWidth * MM_PER_INCH / header.HWResolution[0];
        }

        if (label_height > 0)
        {
            height_mm = label_height;
        }
        else
        {
            height_mm = header.cupsHeight * MM_PER_INCH / header.HWResolution[1];
        }

        fprintf(stderr, "DEBUG: Label size: %.1f x %.1f mm\n", width_mm, height_mm);

        /* Output TSPL header */
        output_tspl_header(output, width_mm, height_mm, density, speed);

        /* Allocate line buffer */
        line_buffer = malloc(header.cupsBytesPerLine);
        if (!line_buffer)
        {
            fprintf(stderr, "ERROR: Unable to allocate line buffer\n");
            return;
        }

        /* Output bitmap data */
        output_bitmap_data(output, &header, line_buffer, ras);

        /* Finish the job */
        fprintf(output, "PRINT 1\n");

        /* Cleanup */
        free(line_buffer);
    }
}

static void output_tspl_header(FILE *output, double width_mm, double height_mm,
                               int density, int speed)
{
    fprintf(output, "SIZE %.1f mm,%.1f mm\n", width_mm, height_mm);
    fprintf(output, "GAP %d mm,0\n", DEFAULT_GAP);
    fprintf(output, "DENSITY %d\n", density);
    fprintf(output, "SPEED %d\n", speed);
    fprintf(output, "DIRECTION 1\n");
    fprintf(output, "CLS\n");
}

static void output_bitmap_data(FILE *output, cups_page_header2_t *header,
                               unsigned char *line_buffer, cups_raster_t *ras)
{
    unsigned int y;
    unsigned int width_bytes;
    unsigned char *bitmap_line;

    /* Calculate width in bytes (8 pixels per byte) - критично важливо! */
    width_bytes = (header->cupsWidth + 7) / 8;

    /* Allocate bitmap line buffer */
    bitmap_line = malloc(width_bytes);
    if (!bitmap_line)
    {
        fprintf(stderr, "ERROR: Unable to allocate bitmap line buffer\n");
        return;
    }

    /* Output BITMAP command header */
    fprintf(output, "BITMAP 0,0,%u,%u,0,", width_bytes, header->cupsHeight);

    /* Process each line */
    for (y = 0; y < header->cupsHeight; y++)
    {
        unsigned int x, bit, byte_pos;

        /* Read line from raster */
        if (cupsRasterReadPixels(ras, line_buffer, header->cupsBytesPerLine) < 1)
        {
            fprintf(stderr, "ERROR: Unable to read line %u\n", y);
            break;
        }

        /* Clear bitmap line */
        memset(bitmap_line, 0, width_bytes);

        /* Convert pixels to bitmap format */
        for (x = 0; x < header->cupsWidth; x++)
        {
            unsigned char pixel = 0;

            byte_pos = x / 8;
            bit = 7 - (x % 8); /* MSB is leftmost pixel для TSPL */

            /* Get pixel value and convert to binary */
            if (header->cupsBitsPerPixel == 1)
            {
                /* Monochrome - читаємо з CUPS формату */
                unsigned int src_byte = x / 8;
                unsigned int src_bit = 7 - (x % 8);
                unsigned char cups_pixel = (line_buffer[src_byte] >> src_bit) & 1;
                /* CUPS: 0=чорний,1=білий → TSPL: 1=чорний,0=білий */
                pixel = cups_pixel ? 1 : 0;
            }
            else if (header->cupsBitsPerPixel == 8)
            {
                /* Grayscale - поріг 128 */
                unsigned char gray_value = line_buffer[x];
                /* Темні пікселі стають чорними в TSPL */
                pixel = (gray_value < 128) ? 1 : 0;
            }
            else if (header->cupsBitsPerPixel == 24)
            {
                /* RGB - беремо середнє */
                unsigned int offset = x * 3;
                if (offset + 2 < header->cupsBytesPerLine)
                {
                    unsigned int r = line_buffer[offset];
                    unsigned int g = line_buffer[offset + 1];
                    unsigned int b = line_buffer[offset + 2];
                    unsigned int luminance = (r * 299 + g * 587 + b * 114) / 1000;
                    pixel = (luminance < 128) ? 1 : 0;
                }
            }
            else
            {
                /* Інші формати - загальний підхід */
                int bytes_per_pixel = header->cupsBitsPerPixel / 8;
                if (bytes_per_pixel > 0)
                {
                    unsigned int offset = x * bytes_per_pixel;
                    unsigned int sum = 0;
                    for (int i = 0; i < bytes_per_pixel && (offset + i) < header->cupsBytesPerLine; i++)
                    {
                        sum += line_buffer[offset + i];
                    }
                    unsigned int average = sum / bytes_per_pixel;
                    pixel = (average < 128) ? 1 : 0;
                }
            }

            /* Set bit in bitmap if pixel is black */
            if (pixel)
            {
                bitmap_line[byte_pos] |= (1 << bit);
            }
        }

        /* Output bitmap line as hex */
        fwrite(bitmap_line, 1, width_bytes, output);
    }

    fprintf(output, "\n");
    free(bitmap_line);
}
