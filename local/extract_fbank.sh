#!/bin/bash
. ./path.sh
fbankdir=data/fbank
mkdir -p $fbankdir
for part in cyberon_train cyberon_test ; do
  compute-fbank-feats --allow_downsample=true --verbose=2 --config=conf/fbank.conf scp,p:data/$part/wav.scp ark,t:$fbankdir/$part.ark
done
