#!/bin/bash
. ./local/data/corpus_path.sh
mkdir -p ./data/PTS

cp $corpus/PTS_segmented/{text,segments} ./data/PTS/
for x in wav.scp utt2spk ; do
    python3 local/data/data_prep_PTS.py $PTS $x | sort -k1,1 -u > data/PTS/$x || exit 1;
done
cat data/PTS/utt2spk | utils/utt2spk_to_spk2utt.pl > data/PTS/spk2utt || exit 1;
utils/fix_data_dir.sh data/PTS || exit 1;
