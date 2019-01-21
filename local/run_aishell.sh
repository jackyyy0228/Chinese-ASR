#/bin/bash

. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh
mfccdir=data/mfcc
fbankdir=data/fbank
nj=40
stage=6
lang=data/wfst/lang
lang_test=data/wfst/lang_test
mkdir -p $mfccdir

if [ $stage -le 0 ]; then
  local/data/data_prep_aishell2.sh
  utils/subset_data_dir_tr_cv.sh --cv-spk-percent 5 data/aishell2/mfcc39 data/aishell2_train/mfcc39 data/aishell2_dev/mfcc39
fi
# Now make MFCC features.
if [ $stage -le 1 ]; then
  # mfccdir should be some place with a largish disk where you
  # want to store MFCC features.
  for corpus in aishell2_train aishell2_dev ; do
    data=./data/$corpus/mfcc39
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
  done
  # subset the training data for fast startup
  for x in 100 300; do
    utils/subset_data_dir.sh data/aishell2_train/mfcc39 ${x}000 data/aishell2_train/train_${x}k_mfcc39
  done
  for corpus in aishell2_train aishell2_dev ; do
    data_mfcc=./data/$corpus/mfcc39
    data=./data/$corpus/fbank
    utils/copy_data_dir.sh $data_mfcc $data
    utils/fix_data_dir.sh $data

    steps/make_fbank.sh --nj $nj --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $corpus \
        $data exp/make_fbank/corpus $fbankdir
    steps/compute_cmvn_stats.sh --name $corpus $data exp/make_fbank/$corpus $fbankdir
  done

fi

# mono
if [ $stage -le 2 ]; then
  # training
  #steps/train_mono.sh --cmd "$train_cmd" --nj $nj \
  #  data/aishell2_train/train_100k_mfcc39 $lang exp/aishell2/mono || exit 1;
  
  # decoding
  #utils/mkgraph.sh $lang_test exp/aishell2/mono exp/aishell2/mono/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd" --nj $nj --config conf/decode.config \
    exp/aishell2/mono/graph data/aishell2_dev/mfcc39 exp/aishell2/mono/decode_dev

  # alignment
  steps/align_si.sh --cmd "$train_cmd" --nj $nj \
    data/aishell2_train/train_300k_mfcc39 $lang exp/aishell2/mono exp/aishell2/mono_ali || exit 1;
fi 

# tri1
if [ $stage -le 3 ]; then
  # training
  steps/train_deltas.sh --cmd "$train_cmd" \
   4000 32000 data/aishell2_train/train_300k_mfcc39 $lang exp/aishell2/mono_ali exp/aishell2/tri1 || exit 1;
  
  # decoding
  utils/mkgraph.sh $lang_test exp/aishell2/tri1 exp/aishell2/tri1/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd" --nj $nj --config conf/decode.config \
    exp/aishell2/tri1/graph data/aishell2_dev/mfcc39 exp/aishell2/tri1/decode_dev
  
  # alignment
  steps/align_si.sh --cmd "$train_cmd" --nj $nj \
    data/aishell2_train/train_300k_mfcc39 $lang exp/aishell2/tri1 exp/aishell2/tri1_ali || exit 1;
fi

# tri2
if [ $stage -le 4 ]; then
  # training
  steps/train_deltas.sh --cmd "$train_cmd" \
   7000 56000 data/aishell2_train/mfcc39 $lang exp/aishell2/tri1_ali exp/aishell2/tri2 || exit 1;
  
  # decoding
  utils/mkgraph.sh $lang_test exp/aishell2/tri2 exp/aishell2/tri2/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd" --nj $nj --config conf/decode.config \
    exp/aishell2/tri2/graph data/aishell2_dev/mfcc39 exp/aishell2/tri2/decode_dev

  # alignment
  steps/align_si.sh --cmd "$train_cmd" --nj $nj \
   data/aishell2_train/mfcc39 $lang exp/aishell2/tri2 exp/aishell2/tri2_ali || exit 1;
fi

# tri3
if [ $stage -le 5 ]; then
  # training [LDA+MLLT]
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
   10000 80000 data/aishell2_train/mfcc39 $lang exp/aishell2/tri2_ali exp/aishell2/tri3 || exit 1;
  
  # decoding
  utils/mkgraph.sh $lang_test exp/aishell2/tri3 exp/aishell2/tri3/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd" --nj $nj --config conf/decode.config \
    exp/aishell2/tri3/graph data/aishell2_dev/mfcc39 exp/aishell2/tri3/decode_dev

  # alignment
  steps/align_si.sh --cmd "$train_cmd" --nj $nj \
    data/aishell2_train/mfcc39 $lang exp/aishell2/tri3 exp/aishell2/tri3_ali || exit 1;
  # alignment 
  steps/align_si.sh --cmd "$train_cmd" --nj $nj \
    data/aishell2_dev/mfcc39 $lang exp/aishell2/tri3 exp/aishell2/tri3_ali_dev || exit 1;
  
fi

if [ $stage -le 6 ]; then
  for corpus in train train_sp ; do
    data=./data/$corpus/mfcc39
    steps/make_mfcc.sh --cmd "$train_cmd" --nj 100 --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
  done

  #Align
  steps/align_si.sh --cmd "$train_cmd" --nj $nj \
    data/train/mfcc39 $lang exp/aishell2/tri3 exp/aishell2/tri3_ali_taiwanese_train || exit 1;

  # training [LDA+MLLT]
  steps/train_lda_mllt.sh --cmd "$train_cmd" --train_tree false \
   10000 80000 data/train/mfcc39 $lang exp/aishell2/tri3_ali_taiwanese_train exp/aishell2/tri4_taiwanese || exit 1;
  
  # decoding
  utils/mkgraph.sh $lang_test exp/aishell2/tri4_taiwanese exp/aishell2/tri4_taiwanese/graph || exit 1;
  steps/decode.sh --cmd "$decode_cmd" --nj 12 --config conf/decode.config \
    exp/aishell2/tri4_taiwanese/graph data/cyberon_chinese_test/mfcc39 exp/aishell2/tri4_taiwanese/decode_cyberon_chinese_test
  
  #align
  steps/align_si.sh --cmd "$train_cmd" --nj $nj \
    data/train_sp/mfcc39 $lang exp/aishell2/tri4_taiwanese exp/aishell2/tri4_ali_train_sp || exit 1;

fi


echo "run_aishell.sh succeeded"
exit 0;
