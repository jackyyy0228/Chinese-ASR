#!/bin/bash
. ./local/data/corpus_path.sh
data=./data/PTS
mkdir -p $data

cp $corpus/PTS_segmented/{text,segments} $data/

cat $corpus/PTS_segemted/segments | awk '{print $1 " " $1}' | sort -k1,1 -u > $data/utt2spk

for x in wav.scp  ; do
    python3 local/data/data_prep_PTS.py $PTS $x | sort -k1,1 -u > $data/$x || exit 1;
done

cat $data/utt2spk | utils/utt2spk_to_spk2utt.pl > $data/spk2utt || exit 1;
utils/fix_data_dir.sh $data || exit 1;
