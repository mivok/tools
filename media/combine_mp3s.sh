#!/bin/bash
# vim: ts=8 sw=2 sts=2 et
# This script combines multiple MP3 files into a single MP3 file using ffmpeg.
# Usage: ./combine_mp3s.sh -o output.mp3 input1.mp3 input2.mp3 ...
# Requires ffmpeg to be installed.

usage() {
  echo "Usage: $0 [-o output_file] input1.mp3 [input2.mp3...]"
  echo
  echo "Combine multiple MP3 files into a single MP3 file."
  echo "  -o output_file  Specify the output file name"
  echo "                  (default: output.mp3)."
  echo "  -h              Display this help message."
}

# Parse command line arguments
OUTPUT_FILE="output.mp3"
while getopts ":ho:" opt; do
  case $opt in
    o)
      OUTPUT_FILE="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

ffmpeg -f concat -safe 0 -i <(for f in "$@"; do echo "file '$PWD/$f'"; done) \
  -c copy "$OUTPUT_FILE"
