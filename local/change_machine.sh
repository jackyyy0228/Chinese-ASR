#!/bin/bash

for dir in exp/nnet3/ivectors_cyberon_chinese_test exp/nnet3/ivectors_TOCFL; do
  for scp in $dir/*.scp ; do
    cat $scp | sed 's/jackyyy/jacky\/work/g' > ${scp}2
    mv ${scp}2 $scp
    echo "Changing path of $dir/$scp"
  done
done
