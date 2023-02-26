#!/bin/bash

countFiles () {
    local dir=$1
    local count=$(find "$dir" -type f | wc -l)
    echo "$count files in $dir"
}

for dir in "$@"; do
    countFiles "$dir"
done
