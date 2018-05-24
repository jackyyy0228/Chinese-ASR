#!/bin/bash

train_data=./data/cyberon_train
test_data=./data/cyberon_test
exp_dir=./exp/cyberon
stage=7


if [ $stage -le 1 ]; then
  #data_prep
  bash local/data_prep_cyberon.sh
fi

#data prep will raise encoding error if we set LC_all=C
. ./path.sh
. ./cmd.sh

if [ $stage -le 2 ]; then
  #prepare dictionary lexicon
  local/prepare_ch_dict.sh
  # Phone Sets, questions, L compilation                                                                                                      
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
  # LM training
  local/hkust_train_lms.sh 
  #G compilation, check LG composition
  local/hkust_format_data.sh
  for part in cyberon_train cyberon_test ; do
    utils/fix_data_dir.sh data/$part || exit 1;
  done
fi

#extract spectrogram
if [ $stage -le 3 ]; then
  specdir=data/spectrogram
  mkdir -p $specdir
  for part in cyberon_train cyberon_test ; do
    compute-spectrogram-feats --allow_downsample=true scp,p:data/$part/wav.scp ark,t:$specdir/$part.ark
  done
fi

# make mfcc
if [ $stage -le 4 ]; then
  mfccdir=data/mfcc
  mkdir -p $mfccdir
  for part in cyberon_train cyberon_test ; do
    steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj 6 data/$part exp/make_mfcc/$part $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir || exit 1;
  done
fi

if [ $stage -le 5 ]; then

  steps/train_mono.sh --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/mono0a || exit 1;

 # Monophone decoding
 utils/mkgraph.sh data/lang_test $exp_dir/mono0a $exp_dir/mono0a/graph || exit 1
 steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj 8 \
   $exp_dir/mono0a/graph data/cyberon_test $exp_dir/mono0a/decode

 # Get alignments from monophone system.
 steps/align_si.sh --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/mono0a $exp_dir/mono_ali || exit 1;

 # train tri1 [first triphone pass]
 steps/train_deltas.sh --cmd "$train_cmd" \
  2500 20000 data/cyberon_train data/lang $exp_dir/mono_ali $exp_dir/tri1 || exit 1;

 # decode tri1
 utils/mkgraph.sh data/lang_test $exp_dir/tri1 $exp_dir/tri1/graph || exit 1;
 steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj 10 \
   $exp_dir/tri1/graph data/cyberon_test $exp_dir/tri1/decode

 # align tri1
 steps/align_si.sh --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/tri1 $exp_dir/tri1_ali || exit 1;

 # train tri2 [delta+delta-deltas]
 steps/train_deltas.sh --cmd "$train_cmd" \
  2500 20000 data/cyberon_train data/lang $exp_dir/tri1_ali $exp_dir/tri2 || exit 1;

 # decode tri2
 utils/mkgraph.sh data/lang_test $exp_dir/tri2 $exp_dir/tri2/graph
 steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj 10 \
   $exp_dir/tri2/graph data/cyberon_test $exp_dir/tri2/decode

 # train and decode tri2b [LDA+MLLT]

 steps/align_si.sh --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/tri2 $exp_dir/tri2_ali || exit 1;

 # Train tri3a, which is LDA+MLLT,
 steps/train_lda_mllt.sh --cmd "$train_cmd" \
  2500 20000 data/cyberon_train data/lang $exp_dir/tri2_ali $exp_dir/tri3a || exit 1;

 utils/mkgraph.sh data/lang_test $exp_dir/tri3a $exp_dir/tri3a/graph || exit 1;
 steps/decode.sh --cmd "$decode_cmd" --nj 8 --config conf/decode.config \
   $exp_dir/tri3a/graph data/cyberon_test $exp_dir/tri3a/decode
 # From now, we start building a more serious system (with SAT), and we"ll
 # do the alignment with fMLLR.

 steps/align_fmllr.sh --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/tri3a $exp_dir/tri3a_ali || exit 1;

 steps/train_sat.sh --cmd "$train_cmd" \
   2500 20000 data/cyberon_train data/lang $exp_dir/tri3a_ali $exp_dir/tri4a || exit 1;

 utils/mkgraph.sh data/lang_test $exp_dir/tri4a $exp_dir/tri4a/graph
 steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 8 --config conf/decode.config \
   $exp_dir/tri4a/graph data/cyberon_test $exp_dir/tri4a/decode

 steps/align_fmllr.sh  --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/tri4a $exp_dir/tri4a_ali

 # Building a larger SAT system.

 steps/train_sat.sh --cmd "$train_cmd" \
   3500 100000 data/cyberon_train data/lang $exp_dir/tri4a_ali $exp_dir/tri5a || exit 1;

 utils/mkgraph.sh data/lang_test $exp_dir/tri5a $exp_dir/tri5a/graph || exit 1;
 steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 10 --config conf/decode.config \
    $exp_dir/tri5a/graph data/cyberon_test $exp_dir/tri5a/decode || exit 1;

 steps/align_fmllr.sh --cmd "$train_cmd" --nj 10 \
   data/cyberon_train data/lang $exp_dir/tri5a $exp_dir/tri5a_ali || exit 1;
fi


if [ $stage -le 6 ]; then
 steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj 8 \
   $exp_dir/mono0a/graph data/cyberon_test $exp_dir/mono0a/decode
 steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj 8 \
   $exp_dir/tri1/graph data/cyberon_test $exp_dir/tri1/decode
 
 steps/train_sat.sh --cmd "$train_cmd" \
   4500 120000 data/cyberon_train data/lang $exp_dir/tri5a_ali $exp_dir/tri5a_4500_120000 || exit 1;

 utils/mkgraph.sh data/lang_test $exp_dir/tri5a_4500_120000 $exp_dir/tri5a_4500_120000/graph || exit 1;
 steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 8 --config conf/decode.config \
    $exp_dir/tri5a_4500_120000/graph data/cyberon_test $exp_dir/tri5a_4500_120000/decode || exit 1;

 steps/align_fmllr.sh --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/tri5a_4500_120000 $exp_dir/tri5a_4500_120000_ali || exit 1;
 
 steps/train_sat.sh --cmd "$train_cmd" \
   4500 120000 data/cyberon_train data/lang $exp_dir/tri5a_ali $exp_dir/tri5a_2500_80000 || exit 1;

 utils/mkgraph.sh data/lang_test $exp_dir/tri5a_2500_80000 $exp_dir/tri5a_2500_80000/graph || exit 1;
 steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 8 --config conf/decode.config \
    $exp_dir/tri5a_2500_80000/graph data/cyberon_test $exp_dir/tri5a_2500_80000/decode || exit 1;

 steps/align_fmllr.sh --cmd "$train_cmd" --nj 8 \
   data/cyberon_train data/lang $exp_dir/tri5a_2500_80000 $exp_dir/tri5a_2500_80000_ali || exit 1;
fi
if [ $stage -le 7 ]; then
  #local/run_discriminative.sh $exp_dir/tri5a
  local/nnet3/run_tdnn_lstm.sh
  #local/run_sgmm.sh $exp_dir/tri5a
fi

