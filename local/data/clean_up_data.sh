#!/bin/bash
. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh

set -e
set -u
set -o pipefail

data=./data/kaggle3/mfcc39_pitch9
name=kaggle3
nj=40

steps/align_fmllr.sh  --cmd "$train_cmd" --nj $nj \
  $data data/lang exp/tri4a exp/tri4a_ali_$name || exit 1;

steps/cleanup/clean_and_segment_data.sh --cmd "$train_cmd" --nj $nj $data data/lang \
  exp/tri4a_ali_$name exp/tri4a_cleanup_$name data/kaggle3/cleaned_mfcc39_pitch9 || exit 1;
