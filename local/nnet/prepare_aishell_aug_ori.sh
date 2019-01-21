#!/bin/bash
fbankdir=data/fbank
stage=3
. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh

set -euo pipefail

if [ $stage -le 0 ]; then
  local/data/data_prep_noise.sh
fi


if [ $stage -le 2 ]; then
  #check copy_alignment.sh first
  #rm -r exp/aishell2/tri3_ali_train_aug_ori
  cp -r exp/aishell2/tri3_ali exp/aishell2/tri3_ali_train_aug_ori
  local/nnet/copy_alignment.sh exp/aishell2/tri3_ali_train_aug_ori

  #rm -r exp/aishell2/tri3_ali_dev_aug_ori
  cp -r exp/aishell2/tri3_ali_dev exp/aishell2/tri3_ali_dev_aug_ori
  local/nnet/copy_alignment.sh exp/aishell2/tri3_ali_dev_aug_ori

  cp -r exp/aishell2/tri4_ali_train_sp exp/aishell2/tri4_ali_train_sp_aug_ori
  local/nnet/copy_alignment.sh exp/aishell2/tri4_ali_train_sp_aug_ori
fi

if [ $stage -le 3 ]; then
  # dividing train_sp
  rm -r data/aishell2_train_aug_ori/fbank
  utils/combine_data.sh data/aishell2_train_aug_ori/fbank data/aishell2_train_aug/fbank data/aishell2_train/fbank
  #utils/combine_data.sh data/aishell2_dev_aug_ori/fbank data/aishell2_dev_aug/fbank data/aishell2_dev/fbank
  #utils/combine_data.sh data/train_sp_aug_ori/fbank data/train_sp/fbank data/train_sp_aug/fbank
  rm -r data/train_sp_aug_ori_for_train/fbank data/train_sp_aug_ori_for_dev/fbank
  utils/subset_data_dir_tr_cv.sh --cv-spk-percent 2 data/train_sp_aug_ori/fbank \
    data/train_sp_aug_ori_for_train/fbank data/train_sp_aug_ori_for_dev/fbank

  rm -r data/train_sp_aishell_for_train_aug_ori/fbank data/train_sp_aishell_for_dev_aug_ori/fbank
  utils/combine_data.sh data/train_sp_aishell_for_train_aug_ori/fbank \
    data/train_sp_aug_ori_for_train/fbank data/aishell2_train_aug_ori/fbank
  utils/combine_data.sh data/train_sp_aishell_for_dev_aug_ori/fbank \
    data/train_sp_aug_ori_for_dev/fbank data/aishell2_dev_aug_ori/fbank

  rm -r exp/tri4a_train_sp_aishell_for_train_aug_ori_ali exp/tri4a_train_sp_aishell_for_dev_aug_ori_ali
  steps/combine_ali_dirs.sh --num-jobs 40 data/train_sp_aishell_for_train/fbank exp/tri4a_train_sp_aishell_for_train_aug_ori_ali \
    exp/aishell2/tri4_ali_train_sp_aug_ori exp/aishell2/tri3_ali_train_aug_ori
  steps/combine_ali_dirs.sh --num-jobs 40 data/train_sp_aishell_for_dev/fbank exp/tri4a_train_sp_aishell_for_dev_aug_ori_ali \
    exp/aishell2/tri4_ali_train_sp_aug_ori exp/aishell2/tri3_ali_dev_aug_ori
fi
