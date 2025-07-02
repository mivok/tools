#!/bin/bash
# Convert duckbox formatted output into csv
# Based on the sed scripts at
# https://duckdb.org/docs/stable/guides/snippets/importing_duckbox_tables.html

input_file=""
output_file=""
while [[ -n "$1" ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: duckbox_to_csv.sh [OPTIONS]"
            echo
            echo "Convert duckbox formatted output into CSV format."
            echo
            echo "Options:"
            echo "  -h, --help        Show this help message and exit"
            echo "  -i, --input FILE  Specify input file (default: stdin)"
            echo "  -o, --output FILE Specify output file (default: stdout)"
            exit 0
            ;;
        -i|--input)
            if [[ -n "$2" ]]; then
                input_file="$2"
                shift 2
            else
                echo "Error: --input requires a file argument."
                exit 1
            fi
            ;;
        -o|--output)
            if [[ -n "$2" ]]; then
                output_file="$2"
                shift 2
            else
                echo "Error: --output requires a file argument."
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -n "$input_file" ]]; then
    exec < "$input_file"
fi

if [[ -n "$output_file" ]]; then
    exec > "$output_file"
fi

# The actual sed command to do the conversion, loosely based on the DuckDB
# documentation but using a single sed command and dealing with the rows/columns
# output as well.
sed -e '1d;3,4d;$d' \
    -e '/^├/d; /^│ [0-9]* rows/d' \
    -e 's/^│ *//;s/ *│$//;s/ *│ */,/g'
