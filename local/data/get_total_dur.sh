#!/bin/bash
datadir=$1
bash utils/data/get_utt2dur.sh $datadir
python local/data/get_total_dur.py $datadir
