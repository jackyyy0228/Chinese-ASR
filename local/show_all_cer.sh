#!/bin/bash
dirs=$1
[ -z $dirs ] && dirs="exp/* exp/nnet/* exp/aishell2/* exp/nnet/aishell2/*"
for x in $dirs/decode*; do 
  [ -d $x ] && grep WER $x/cer_* | utils/best_wer.sh; 
done
