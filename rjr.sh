#!/bin/bash
DIST_DIR="./rjr_temp_dir"
CLASSPATH=""

args=""
skip=false
for i in $(seq 1 $(($# - 1))); do
    if $skip; then
        skip=false
        continue
    fi
    if [[ "${!i}" == "-cp" ]] && [ -z "$CLASSPATH"  ]; then
        next_index=$((i + 1))
        CLASSPATH=${!next_index}
    fi

    if [[ "${!i}" != "-d" ]]; then
        args="$args ${!i}"
    else
        skip=true    
    fi
done

args="$args -d $DIST_DIR ${!#}"

if [ -d "$DIST_DIR" ]; then
    rm -rf "$DIST_DIR"
fi
mkdir "$DIST_DIR"

file_name=$(basename ${!#})
class_name=$(echo "$file_name" | sed 's/\.[^.]*$//')
resolved_package=$(grep -m 1 '^package' ${!#} | sed 's/package //; s/;//')

if [[ -z "$resolved_package" ]]; then
    resolved_class=$class_name
else
    resolved_class="$resolved_package.$class_name"
fi

javac $args

java -cp "$CLASSPATH:$DIST_DIR" $resolved_class 

rm -rf "$DIST_DIR"
