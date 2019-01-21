#!/bin/bash
AUDIO_DATA_PREP=false
LANG_DATA_PREP=true
EXTRACT_MFCC=false

TRAIN_MONO=true
TRAIN_TRI=true
TRAIN_CHAIN=false

nj=8 #number of job parallel running

if [ $AUDIO_DATA_PREP = true ] ; then
  echo "Preparing audio data..."
  for corpus in cyberon_chinese PTS NER TOCFL MATBN ; do
    local/data/data_prep_${corpus}.sh
  done
fi

. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh

if [ $LANG_DATA_PREP = true ] ; then
  echo "Preparing lang data..."
  #prepare dictionary lexicon
  local/prepare_dict.sh --vocabulary-size 50000 --dict_dir data/local/dict_tmp --stage 0 || exit 1
  # Phone Sets, questions, L compilation                                                                                                      
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
  
  # LM training
  local/train_lms.sh --lm-type 3gram-mincount
  # LM pruning : to ensure G.fst < 70Mb
  prune_lm.sh --arpa 10.0 ./data/local/lm/3gram-mincount
  #G compilation, check LG composition
  local/format_data.sh data/local/lm/3gram-mincount/lm_pr10.0.gz data/lang_3small_test
  #LM (middle size)
  prune_lm.sh --arpa 4.0 ./data/local/lm/3gram-mincount
  local/format_data.sh data/local/lm/3gram-mincount/lm_pr4.0.gz data/lang_3mid_test
  #4-gram LM (the largest)
  local/train_lms.sh --lm-type 4gram-mincount
  prune_lm.sh --arpa 10.0 ./data/local/lm/4gram-mincount
  local/format_data.sh data/local/lm/4gram-mincount/lm_pr10.0.gz data/lang_4large_test
  
fi


if [ $EXTRACT_MFCC = true ] ; then
  local/extract_mfcc.sh --nj $nj --stage 0
fi

exp_dir=./exp
traindata=./data/train/mfcc39_pitch9
testdata_affix="TOCFL cyberon_chinese_test"

if [ $TRAIN_MONO = true ] ; then
  echo "Training Monophone models...."
  utils/subset_data_dir.sh --shortest data/train/mfcc39_pitch9 10000 data/train_10kshort/mfcc39_pitch9
  utils/subset_data_dir.sh  data/train/mfcc39_pitch9 50000 data/train_50k/mfcc39_pitch9
  utils/subset_data_dir.sh  data/train/mfcc39_pitch9 200000 data/train_200k/mfcc39_pitch9
  #Monophone training
  steps/train_mono.sh --cmd "$train_cmd" --nj $nj \
   data/train_10kshort/mfcc39_pitch9 data/lang $exp_dir/mono0a || exit 1;

 # Monophone decoding
 utils/mkgraph.sh data/lang_3small_test $exp_dir/mono0a $exp_dir/mono0a/graph || exit 1
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/mono0a/graph data/$affix/mfcc39_pitch9 $exp_dir/mono0a/decode_3small_$affix
 done
 
 # Get alignments from monophone system.
 steps/align_si.sh --cmd "$train_cmd" --nj $nj \
   data/train_50k/mfcc39_pitch9 data/lang $exp_dir/mono0a $exp_dir/mono_ali || exit 1;
  
fi

if [ $TRAIN_TRI = true ] ; then

 # train tri1 [first triphone pass]
 steps/train_deltas.sh --cmd "$train_cmd" \
  2000 10000  data/train_50k/mfcc39_pitch9 data/lang $exp_dir/mono_ali $exp_dir/tri1 || exit 1;

 # decode tri1
 utils/mkgraph.sh data/lang_3small_test $exp_dir/tri1 $exp_dir/tri1/graph || exit 1;
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri1/graph data/$affix/mfcc39_pitch9 $exp_dir/tri1/decode_3small_$affix
 done

 # align tri1
 steps/align_si.sh --cmd "$train_cmd" --nj $nj \
   data/train_200k/mfcc39_pitch9 data/lang $exp_dir/tri1 $exp_dir/tri1_ali || exit 1;

 # train tri2 [delta+delta-deltas]
 steps/train_deltas.sh --cmd "$train_cmd" \
  2500 12500 data/train_200k/mfcc39_pitch9 data/lang $exp_dir/tri1_ali $exp_dir/tri2 || exit 1;

 # decode tri2
 utils/mkgraph.sh data/lang_3small_test $exp_dir/tri2 $exp_dir/tri2/graph
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri2/graph data/$affix/mfcc39_pitch9 $exp_dir/tri2/decode_3small_$affix
 done

 # train and decode tri2b [LDA+MLLT]

 steps/align_si.sh --cmd "$train_cmd" --nj $nj \
   data/train_200k/mfcc39_pitch9 data/lang $exp_dir/tri2 $exp_dir/tri2_ali || exit 1;

 # Train tri3a, which is LDA+MLLT,
 steps/train_lda_mllt.sh --cmd "$train_cmd" \
  3000 30000 data/train_200k/mfcc39_pitch9 data/lang $exp_dir/tri2_ali $exp_dir/tri3a || exit 1;

 utils/mkgraph.sh data/lang_3small_test $exp_dir/tri3a $exp_dir/tri3a/graph || exit 1;
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri3a/graph data/$affix/mfcc39_pitch9 $exp_dir/tri3a/decode_3small_$affix
 done
 # From now, we start building a more serious system (with SAT), and we"ll
 # do the alignment with fMLLR.

 steps/align_fmllr.sh --cmd "$train_cmd" --nj $nj \
   $traindata data/lang $exp_dir/tri3a $exp_dir/tri3a_ali || exit 1;

 steps/train_sat.sh --cmd "$train_cmd" \
   3000 30000 $traindata data/lang $exp_dir/tri3a_ali $exp_dir/tri4a || exit 1;

 utils/mkgraph.sh data/lang_3small_test $exp_dir/tri4a $exp_dir/tri4a/graph
 for affix in $testdata_affix ; do
   steps/decode_fmllr.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri4a/graph data/$affix/mfcc39_pitch9 $exp_dir/tri4a/decode_3small_$affix
   steps/lmrescore.sh --cmd "$decode_cmd" data/lang_3{small,mid}_test \
     data/$affix/mfcc39_pitch9 exp/tri4a/decode_3{small,mid}_$affix
 done

 steps/align_fmllr.sh  --cmd "$train_cmd" --nj $nj \
   $traindata data/lang $exp_dir/tri4a $exp_dir/tri4a_ali

 # Building a larger SAT system.

 steps/train_sat.sh --cmd "$train_cmd" \
   5000 50000 $traindata data/lang $exp_dir/tri4a_ali $exp_dir/tri5a || exit 1;

 utils/mkgraph.sh data/lang_3small_test $exp_dir/tri5a $exp_dir/tri5a/graph || exit 1;
 for affix in $testdata_affix ; do
   steps/decode_fmllr.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri5a/graph data/$affix/mfcc39_pitch9 $exp_dir/tri5a/decode_3small_$affix
   steps/lmrescore.sh --cmd "$decode_cmd" data/lang_3{small,mid}_test \
     data/$affix/mfcc39_pitch9 exp/tri4a/decode_3{small,mid}_$affix
 done

 steps/align_fmllr.sh --cmd "$train_cmd" --nj $nj \
   $traindata data/lang $exp_dir/tri5a $exp_dir/tri5a_ali || exit 1;
fi

if [ $TRAIN_CHAIN = true ] ; then
  local/nnet3/run_ivector_common.sh --gmm $exp_dir/tri5a --nj $nj --traindata data/train
  local/nnet3/run_tdnn_lstm.sh 
fi
## Show all the performance of the aboves models
local/show_all_cer.sh





