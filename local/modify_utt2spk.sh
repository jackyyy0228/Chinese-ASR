#!/bin/bash
datadir=$1
if [ -f $datadir/utt2spk ] ; then
  mv $datadir/utt2spk $datadir/utt2spk_backup
  cat $datadir/utt2spk_backup | awk '{print $1 " " $1}' > $datadir/utt2spk
  cat $datadir/utt2spk | utils/utt2spk_to_spk2utt.pl > $datadir/spk2utt || exit 1;
  utils/fix_data_dir.sh $data || exit 1;
fi
