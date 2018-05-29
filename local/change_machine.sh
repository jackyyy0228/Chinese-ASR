#!/bin/bash

for dir in ./data/*/*/; do
  if [ -f wav.scp ] ; then
    rm -r $dir/split*
    for scp in cmvn.scp feats.scp ; do
      cat $dir/$scp | sed 's/jacky\/work/jackyyy/g' > $dir/${scp}2
      mv $dir/${scp}2 $dir/$scp
      echo "Changing path of $dir/$scp"
    done
  fi
done
