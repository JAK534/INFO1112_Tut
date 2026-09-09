#!/usr/bin/env bash

#Determine directory to analyse
if [ "$#" -eq 0 ]; then
    TARGET_DIR="$(pwd)"

elif [ "$#" -eq 1 ]; then
    if [ ! -d "$1" ]; then
        echo -e "usage: arg needs to be a directory.\n"
        exit 1
    fi

    TARGET_DIR="$(realpath "$1")"

else
    echo -e "usage: more than 1 arg is not allowed.\n"
    exit 2
fi


# Output files must be in home directory
ANALYSIS_FILE="$HOME/analysisData.log"
SUMMARY_FILE="$HOME/summary.log"


#Find log files modified within the last 7 days,
log_files=()

while IFS= read -r -d '' file; do
    filename=$(basename "$file")

#Dont analyse the created files
    if [[ "$file" == "$ANALYSIS_FILE" || "$file" == "$SUMMARY_FILE" ]]; then
        continue
    fi

    log_files+=("$file")

done < <(
    find "$TARGET_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -name "*log" \
        -mtime -7 \
        -print0 2>/dev/null
)


#Number of matching log files
num_files=${#log_files[@]}

if [ "$num_files" -eq 0 ]; then
    echo -e "No. of modified log files: 0\n"
    exit 0
fi


#Prepare output files
> "$ANALYSIS_FILE"
> "$SUMMARY_FILE"

total_errors=0
max_errors=-1
max_error_file=""


# Analyse each log file
for file in "${log_files[@]}"; do

    error_count=$(grep -i -c "error" "$file" 2>/dev/null || true)

    line="$file: $error_count error(s)"

# stdout
    echo "$line"

# analysisData.log
    echo "$line" >> "$ANALYSIS_FILE"

    total_errors=$((total_errors + error_count))

    if [ "$error_count" -gt "$max_errors" ]; then
        max_errors=$error_count
        max_error_file="$file"
    fi
done


# Summary
summary_output="----------------------------------------
Total Log Files Analyzed: $num_files
Total Errors Found: $total_errors
File with Most Errors: $max_error_file ($max_errors errors)
----------------------------------------"

# stdout
echo "$summary_output"

# summary.log
echo "$summary_output" > "$SUMMARY_FILE"
