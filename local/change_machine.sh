#!/bin/bash
/data/local/kgb/Chinese-ASR/data
/home/jacky/work/kgb/


for dir in data ; do
  for scp in $dir/*/*/*.scp ; do
    cat $scp | sed 's/home\/jackyyy/data\/local/g' > ${scp}2
    mv $scp ${scp}_backup
    mv ${scp}2 $scp
    echo "Changing path of $scp"
  done
done
