#!/bin/bash
. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh
exp_dir=./exp
traindata=./data/train_no_eng/mfcc39_pitch9
testdata_affix="TOCFL cyberon_chinese_test"


steps/train_sat.sh --cmd "$train_cmd" \
 3000 30000 $traindata data/lang $exp_dir/nnet3/tdnn_lstm_no_eng_ali $exp_dir/tri4a_nnet_align || exit 1;

utils/mkgraph.sh data/lang_3small_test $exp_dir/tri4a_nnet_align $exp_dir/tri4a_nnet_align/graph

for affix in $testdata_affix ; do
 steps/decode_fmllr.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
   $exp_dir/tri4a_nnet_align/graph data/$affix/mfcc39_pitch9 $exp_dir/tri4a_nnet_align/decode_3small_$affix
 steps/lmrescore.sh --cmd "$decode_cmd" data/lang_3{small,mid}_test \
   data/$affix/mfcc39_pitch9 exp/tri4a_nnet_align/decode_3{small,mid}_$affix
done


