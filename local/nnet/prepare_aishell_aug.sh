#!/bin/bash
fbankdir=data/fbank
stage=2
. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh

set -euo pipefail

if [ $stage -le 0 ]; then
  local/data/data_prep_noise.sh
fi

if [ $stage -le 1 ]; then
  for corpus in aishell2_dev train_sp ; do
    data=data/$corpus/fbank
    data_aug=data/$corpus\_aug/fbank
    if [ ! -f $data/reco2dur ] ; then
      bash utils/data/get_reco2utt.sh $data || exit 1
    fi

    python2 steps/data/augment_data_dir.py --utt-suffix aug --bg-snrs 20:10:5:3:0 --num-bg-noises 0:1:2 --bg-noise-dir data/esc_speech_noise $data $data_aug
    name=$corpus\_aug
    steps/make_fbank.sh --nj 50 --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $name $data_aug exp/make_fbank/$name $fbankdir
    steps/compute_cmvn_stats.sh --name $name $data_aug exp/make_fbank/$name $fbankdir
  done
fi

if [ $stage -le 2 ]; then
  rm -r exp/aishell2/tri3_ali_train_aug
  cp -r exp/aishell2/tri3_ali exp/aishell2/tri3_ali_train_aug
  local/nnet/copy_alignment.sh exp/aishell2/tri3_ali_train_aug

  rm -r exp/aishell2/tri3_ali_dev_aug
  cp -r exp/aishell2/tri3_ali_dev exp/aishell2/tri3_ali_dev_aug
  local/nnet/copy_alignment.sh exp/aishell2/tri3_ali_dev_aug
  

  cp -r exp/aishell2/tri4_ali_train_sp exp/aishell2/tri4_ali_train_sp_aug
  local/nnet/copy_alignment.sh exp/aishell2/tri4_ali_train_sp_aug
fi

if [ $stage -le 3 ]; then
  # dividing train_sp
  utils/subset_data_dir_tr_cv.sh --cv-spk-percent 5 data/train_sp_aug/fbank data/train_sp_aug_for_train/fbank data/train_sp_aug_for_dev/fbank
  
  utils/combine_data.sh data/train_sp_aishell_for_train/fbank data/train_sp_aug_for_train/fbank data/aishell2_train_aug/fbank
  utils/combine_data.sh data/train_sp_aishell_for_dev/fbank data/train_sp_aug_for_dev/fbank data/aishell2_dev_aug/fbank
  
  steps/combine_ali_dirs.sh --num-jobs 40 data/train_sp_aishell_for_train/fbank exp/tri4a_train_sp_aishell_for_train_ali \
    exp/aishell2/tri4_ali_train_sp_aug exp/aishell2/tri3_ali_train_aug
  steps/combine_ali_dirs.sh --num-jobs 40 data/train_sp_aishell_for_dev/fbank exp/tri4a_train_sp_aishell_for_dev_ali \
    exp/aishell2/tri4_ali_train_sp_aug exp/aishell2/tri3_ali_dev_aug
fi
