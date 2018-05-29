#!/bin/bash
AUDIO_DATA_PREP=false
LANG_DATA_PREP=false
EXTRACT_MFCC=false

TRAIN_MONO=true
TRAIN_TRI=true
TRAIN_CHAIN=true

nj=8 #number of job parallel running

if [ $AUDIO_DATA_PREP = true ] ; then
  echo "Preparing audio data..."
  for corpus in cyberon_chinese cyberon_english PTS NER TOCFL seame Tl ; do
    local/data/data_prep_${corpus}.sh
  done
fi

if [ $LANG_DATA_PREP = true ] ; then
  echo "Preparing lang data..."
  #prepare dictionary lexicon
  local/prepare_dict.sh --vocabulary-size 50000
  # Phone Sets, questions, L compilation                                                                                                      
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
  # LM training
  local/train_lms.sh --lm-type 4gram
  #G compilation, check LG composition
  local/format_data.sh --lm-type 4gram
fi

. ./path.sh
. ./cmd.sh

if [ $EXTRACT_MFCC = true ] ; then
  local/extract_mfcc.sh --nj $nj --stage 0
fi
exit 1

exp_dir=./exp
traindata=./data/train
testdata_affix="TOCFL cyberon_english_test cyberon_chinese_test"

if [ $TRAIN_MONO = true ] ; then
  echo "Training Monophone models...."
  #Monophone training
  steps/train_mono.sh --cmd "$train_cmd" --nj $nj \
   data/train data/lang $exp_dir/mono0a || exit 1;

 # Monophone decoding
 utils/mkgraph.sh data/lang_4gram-mincount_test $exp_dir/mono0a $exp_dir/mono0a/graph || exit 1
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/mono0a/graph data/$affix $exp_dir/mono0a/decode_$affix
 done
 
 # Get alignments from monophone system.
 steps/align_si.sh --cmd "$train_cmd" --nj $nj \
   data/train data/lang $exp_dir/mono0a $exp_dir/mono_ali || exit 1;
  
fi
  


if [ $TRAIN_TRI = true ] ; then

 # train tri1 [first triphone pass]
 steps/train_deltas.sh --cmd "$train_cmd" \
  3000 30000 data/train data/lang $exp_dir/mono_ali $exp_dir/tri1 || exit 1;

 # decode tri1
 utils/mkgraph.sh data/lang_4gram-mincount_test $exp_dir/tri1 $exp_dir/tri1/graph || exit 1;
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri1/graph data/$affix $exp_dir/tri1/decode_$affix
 done

 # align tri1
 steps/align_si.sh --cmd "$train_cmd" --nj $nj \
   data/train data/lang $exp_dir/tri1 $exp_dir/tri1_ali || exit 1;

 # train tri2 [delta+delta-deltas]
 steps/train_deltas.sh --cmd "$train_cmd" \
  3000 30000 data/train data/lang $exp_dir/tri1_ali $exp_dir/tri2 || exit 1;

 # decode tri2
 utils/mkgraph.sh data/lang_4gram-mincount_test $exp_dir/tri2 $exp_dir/tri2/graph
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri2/graph data/$affix $exp_dir/tri2/decode_$affix
 done

 # train and decode tri2b [LDA+MLLT]

 steps/align_si.sh --cmd "$train_cmd" --nj $nj \
   data/train data/lang $exp_dir/tri2 $exp_dir/tri2_ali || exit 1;

 # Train tri3a, which is LDA+MLLT,
 steps/train_lda_mllt.sh --cmd "$train_cmd" \
  2500 20000 data/train data/lang $exp_dir/tri2_ali $exp_dir/tri3a || exit 1;

 utils/mkgraph.sh data/lang_4gram-mincount_test $exp_dir/tri3a $exp_dir/tri3a/graph || exit 1;
 for affix in $testdata_affix ; do
   steps/decode.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri3a/graph data/$affix $exp_dir/tri3a/decode_$affix
 done
 # From now, we start building a more serious system (with SAT), and we"ll
 # do the alignment with fMLLR.

 steps/align_fmllr.sh --cmd "$train_cmd" --nj $nj \
   data/train data/lang $exp_dir/tri3a $exp_dir/tri3a_ali || exit 1;

 steps/train_sat.sh --cmd "$train_cmd" \
   3000 30000 data/train data/lang $exp_dir/tri3a_ali $exp_dir/tri4a || exit 1;

 utils/mkgraph.sh data/lang_4gram-mincount_test $exp_dir/tri4a $exp_dir/tri4a/graph
 for affix in $testdata_affix ; do
   steps/decode_fmllr.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri4a/graph data/$affix $exp_dir/tri4a/decode_$affix
 done

 steps/align_fmllr.sh  --cmd "$train_cmd" --nj $nj \
   data/train data/lang $exp_dir/tri4a $exp_dir/tri4a_ali

 # Building a larger SAT system.

 steps/train_sat.sh --cmd "$train_cmd" \
   5000 120000 data/train data/lang $exp_dir/tri4a_ali $exp_dir/tri5a || exit 1;

 utils/mkgraph.sh data/lang_4gram-mincount_test $exp_dir/tri5a $exp_dir/tri5a/graph || exit 1;
 for affix in $testdata_affix ; do
   steps/decode_fmllr.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
     $exp_dir/tri5a/graph data/$affix $exp_dir/tri5a/decode_$affix
 done

 steps/align_fmllr.sh --cmd "$train_cmd" --nj $nj \
   data/train data/lang $exp_dir/tri5a $exp_dir/tri5a_ali || exit 1;
fi

if [ $TRAIN_CHAIN = true ] ; then
fi


