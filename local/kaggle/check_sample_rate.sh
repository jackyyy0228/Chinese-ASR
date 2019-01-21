#!/bin/bash
wav_dir=$1
for wav in $wav_dir/*.wav ; do
  sr=`sox --i -r $wav`
  if [ "$sr" != "16000" ] ; then
    echo $wav $sr
    name=${wav::-4}  
    sox $wav -r 16000 ${name}2.wav
    mv ${name}2.wav $wav
  fi
  name=${wav::-4}  
  sox $wav -t wav -r 16000 -b 16 ${name}2.wav 
  mv ${name}2.wav $wav
done
