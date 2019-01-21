#/bin/bash

. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh
mfccdir=data/mfcc
fbankdir=data/fbank
nj=40
stage=2
lang=data/wfst/lang
lang_test=data/wfst/lang_test
# Now make MFCC features.
if [ $stage -le 1 ]; then
  # mfccdir should be some place with a largish disk where you
  # want to store MFCC features.
  for corpus in cyberon_chinese_test ; do
    data=./data/$corpus/mfcc39
    utils/copy_data_dir.sh ./data/$corpus/mfcc40 $data
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
  done
fi

steps/decode.sh --cmd "$decode_cmd" --nj 12 --config conf/decode.config \
  exp/aishell2/tri3/graph data/cyberon_chinese_test/mfcc39 exp/aishell2/tri3/decode_cyberon_chinese_test
