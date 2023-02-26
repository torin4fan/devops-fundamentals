#!/bin/bash
threshold=1000

checkFreeSpace() {
  while true
  do
      local freeSpace=$(free --mega | grep 'Mem' | awk '{print $4}')

      if [ $freeSpace -lt $1 ]; then
          echo "Warning: Free space is below $1MB"
      fi

      sleep 60
  done
}

if [ $# -gt 0 ]; then
    threshold=$1
fi

if [[ $threshold =~ ^[0-9]+$ ]] && (( $threshold > 0 )); then
    checkFreeSpace $threshold
else
    echo "Variable is not a number or not greater than zero"
fi
