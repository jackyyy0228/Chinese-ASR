#!/bin/bash
for x in exp/cyberon/*/decode*; do 
  [ -d $x ] && grep WER $x/cer_* | utils/best_wer.sh; 
done