#!/bin/bash
# Copyright 2016 Alibaba Robotics Corp. (Author: Xingyu Na)
# Apache2.0

# This runs SGMM training.

. ./cmd.sh
. ./path.sh

exp_dir=exp/cyberon
dir=$1


#steps/train_ubm.sh --cmd "$train_cmd" \
#  450 data/cyberon_train data/lang ${dir}_ali $exp_dir/ubm5a || exit 1;

steps/train_sgmm2.sh --cmd "$train_cmd" \
  7000 17000 data/cyberon_train data/lang ${dir}_ali \
  $exp_dir/ubm5a/final.ubm $exp_dir/sgmm2_5a_2 || exit 1;

utils/mkgraph.sh data/lang_test $exp_dir/sgmm2_5a_2 $exp_dir/sgmm2_5a_2/graph || exit 1;
steps/decode_sgmm2.sh --nj 8 --cmd "$decode_cmd" --config conf/decode.config \
  --transform-dir ${dir}/decode \
  $exp_dir/sgmm2_5a_2/graph data/cyberon_test $exp_dir/sgmm2_5a_2/decode || exit 1;

exit 0;
