#!/usr/bin/env python3
# add_bins_to_refgene.py - part of FLUMIP, under its MIT licence.
#
# Prepends the UCSC bin column to a genePred file that lacks it, so that
# bigGenePredToGenePred output (used for hs1) has the refGene.txt layout
# MIPGEN's exon extraction expects. The bin numbers follow the standard UCSC
# binning scheme (binRange).
#
# usage: add_bins_to_refgene.py <input_file> [<output_file>]
import sys

# Define the bin offsets. (Computed as: 512+64+8+1, 64+8+1, 8+1, 1, 0)
bin_offsets = [585, 73, 9, 1, 0]

# Constants for shifting.
BIN_FIRST_SHIFT = 17  # How much to shift to get to the finest bin.
BIN_NEXT_SHIFT = 3    # How much to shift to get to the next larger bin.

def bin_from_range_standard(start, end):
    """
    Given start and end coordinates (in chromosome coordinates),
    assign them to a bin. There is a bin for each 128k segment,
    for each 1M segment, for each 8M segment, for each 64M segment,
    and for each chromosome (assumed to be less than 512M).
    A range goes into the smallest bin it will fit in.
    
    Parameters:
        start (int): Start coordinate.
        end (int): End coordinate.
        
    Returns:
        int: The bin number.
    
    Raises:
        ValueError: If the start and end are out of range (max is 512M).
    """
    start_bin = start >> BIN_FIRST_SHIFT
    end_bin = (end - 1) >> BIN_FIRST_SHIFT
    
    for offset in bin_offsets:
        if start_bin == end_bin:
            return offset + start_bin
        start_bin >>= BIN_NEXT_SHIFT
        end_bin >>= BIN_NEXT_SHIFT
    
    raise ValueError(f"start {start}, end {end} out of range in findBin (max is 512M)")

def process_line(line):
    """
    Processes a single line by:
      - Splitting on tabs.
      - Extracting the 4th and 5th entries as start and end values.
      - Computing the bins and taking the literal middle entry from the unsorted set.
      - Inserting the middle bin value at the front of the line (followed by a tab).
    """
    fields = line.rstrip().split('\t')
    if len(fields) < 5:
        return line.rstrip()
    
    try:
        start_val = int(fields[3])
        end_val = int(fields[4])
    except ValueError:
        return line.rstrip()
    
    try:
        bin = bin_from_range_standard(start_val, end_val)
    except Exception as e:
        bin = "Error"
    
    return f"{bin}\t{line.rstrip()}"

def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <input_file> [<output_file>]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    output_lines = []
    
    try:
        with open(input_file, 'r') as f:
            for line in f:
                if line.strip():
                    processed = process_line(line)
                    output_lines.append(processed)
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found.")
        sys.exit(1)
    
    if output_file:
        try:
            with open(output_file, 'w') as out_f:
                for out_line in output_lines:
                    out_f.write(out_line + "\n")
            print(f"Processed lines have been written to '{output_file}'.")
        except Exception as e:
            print("Error writing to output file:", e)
    else:
        for out_line in output_lines:
            print(out_line)

if __name__ == '__main__':
    main()
