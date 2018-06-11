#!/bin/bash

# This script is modified based on swbd/s5c/local/nnet3/run_ivector_common.sh

# this script contains some common (shared) parts of the run_nnet*.sh scripts.


stage=0
num_threads_ubm=1
ivector_extractor=
nj=8
traindata=./data/train_no_eng
gmm_dir=exp/tri5a
set -e

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh


align_script=steps/align_fmllr.sh
exp_dir=./exp

steps/align_fmllr.sh  --cmd "$train_cmd" --nj $nj \
 $traindata/mfcc39_pitch9 data/lang $exp_dir/tri4a $exp_dir/tri4a_ali

# Building a larger SAT system.

steps/train_sat.sh --cmd "$train_cmd" \
 5000 80000 $traindata/mfcc39_pitch9 data/lang $exp_dir/tri4a_ali $exp_dir/tri5a || exit 1;

utils/mkgraph.sh data/lang_3small_test $exp_dir/tri5a $exp_dir/tri5a/graph || exit 1;
for affix in $testdata_affix ; do
 steps/decode_fmllr.sh --cmd "$decode_cmd" --config conf/decode.config --nj $nj \
   $exp_dir/tri5a/graph data/$affix/mfcc39_pitch9 $exp_dir/tri5a/decode_3small_$affix
 steps/lmrescore.sh --cmd "$decode_cmd" data/lang_3{small,mid}_test \
   data/$affix/mfcc39_pitch9 exp/tri4a/decode_3{small,mid}_$affix
done

steps/align_fmllr.sh  --cmd "$train_cmd" --nj $nj \
 $traindata/mfcc39_pitch9 data/lang $exp_dir/tri5a $exp_dir/tri5a_ali

if [ $stage -le 2 ] && [ -z $ivector_extractor ]; then
  # Train a system just for its LDA+MLLT transform.  We use --num-iters 13
  # because after we get the transform (12th iter is the last), any further
  # training is pointless.
  steps/train_lda_mllt.sh --cmd "$train_cmd" --num-iters 17 \
    --realign-iters "" \
    --splice-opts "--left-context=3 --right-context=3" \
    30000 60000 $traindata/mfcc40 data/lang \
    ${gmm_dir}_ali exp/nnet3/tri5
fi

if [ $stage -le 3 ] && [ -z $ivector_extractor ]; then
  steps/online/nnet2/train_diag_ubm.sh --cmd "$train_cmd" --nj $nj \
    --num-frames 700000 --num-threads 1  \
    $traindata/mfcc40 512 exp/nnet3/tri5 exp/nnet3/diag_ubm
fi

if [ $stage -le 4 ] && [ -z $ivector_extractor ]; then
  # iVector extractors can in general be sensitive to the amount of data, but
  # this one has a fairly small dim (defaults to 100)
  steps/online/nnet2/train_ivector_extractor.sh --cmd "$train_cmd" --nj $nj  --num-threads 1 --num-processes 1 \
    $traindata/mfcc40 exp/nnet3/diag_ubm exp/nnet3/extractor || exit 1;
  ivector_extractor=exp/nnet3/extractor
fi

if [ $stage -le 5 ]; then
  # Although the nnet will be trained by high resolution data,
  # we still have to perturbe the normal data to get the alignment
  # _sp stands for speed-perturbed
  utils/perturb_data_dir_speed.sh 0.9 $traindata/mfcc39_pitch9 data/temp1
  utils/perturb_data_dir_speed.sh 1.0 $traindata/mfcc39_pitch9 data/temp2
  utils/perturb_data_dir_speed.sh 1.1 $traindata/mfcc39_pitch9 data/temp3
  utils/combine_data.sh --extra-files utt2uniq $traindata\_sp/mfcc39_pitch9 data/temp1 data/temp2 data/temp3
  rm -r data/temp1 data/temp2 data/temp3

  mfccdir=data/mfcc_pitch_sp
  
  name=`basename $traindata\_sp`

  steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj --name $name \
    $traindata\_sp/mfcc39_pitch9 exp/make_mfcc_perturbed/$name $mfccdir || exit 1;
  steps/compute_cmvn_stats.sh --name $name $traindata\_sp/mfcc39_pitch9 exp/make_mfcc/$name $mfccdir || exit 1;
  
  utils/fix_data_dir.sh $traindata\_sp/mfcc39_pitch9
  
  $align_script --nj $nj --cmd "$train_cmd" \
    $traindata\_sp/mfcc39_pitch9 data/lang $gmm_dir ${gmm_dir}_sp_ali || exit 1

  # Now perturb the high resolution data
  utils/copy_data_dir.sh $traindata\_sp/mfcc39_pitch9 $traindata\_sp/mfcc40_pitch3

  mfccdir=data/mfcc_hires_pitch_sp

  steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj --mfcc-config conf/mfcc_hires.conf --name $name \
    $traindata\_sp/mfcc40_pitch3 exp/make_hires/$name $mfccdir || exit 1;
  steps/compute_cmvn_stats.sh $traindata\_sp/mfcc40_pitch3 --name $name exp/make_hires/$name $mfccdir || exit 1;

  utils/fix_data_dir.sh $traindata\_sp/mfcc40_pitch3
  
  # create MFCC data dir without pitch to extract iVector
  mfccdir=data/mfcc_hires
  
  utils/data/limit_feature_dim.sh 0:39 $traindata\_sp/mfcc40_pitch3 $traindata\_sp/mfcc40 || exit 1;
  steps/compute_cmvn_stats.sh --name $name $traindata\_sp/mfcc40 exp/make_hires/$name $mfccdir || exit 1;

  utils/fix_data_dir.sh $traindata\_sp/mfcc40
fi

if [ -z $ivector_extractor ]; then
  echo "iVector extractor is not found!"
  exit 1;
fi

if [ $stage -le 6 ]; then
  rm -f exp/nnet3/.error 2>/dev/null
  train_set=`basename $traindata\_sp`
  trainsp=$traindata\_sp
  ivectordir=exp/nnet3/ivectors_${train_set}

  # We extract iVectors on all the train data, which will be what we train the
  # system on.  With --utts-per-spk-max 2, the script.  pairs the utterances
  # into twos, and treats each of these pairs as one speaker.  Note that these
  # are extracted 'online'.

  # having a larger number of speakers is helpful for generalization, and to
  # handle per-utterance decoding well (iVector starts at zero).
  steps/online/nnet2/copy_data_dir.sh --utts-per-spk-max 2 $trainsp/mfcc40 $trainsp\_max2/mfcc40
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
    $trainsp\_max2/mfcc40 $ivector_extractor $ivectordir \
    || touch exp/nnet3/.error
  [ -f exp/nnet3/.error ] && echo "$0: error extracting iVectors." && exit 1;
fi

if [ $stage -le 7 ]; then
  rm -f exp/nnet3/.error 2>/dev/null
  testdata_affix="TOCFL cyberon_chinese_test"
  for affix in $testdata_affix ; do
    steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
       data/$affix/mfcc40 $ivector_extractor exp/nnet3/ivectors_$affix || touch exp/nnet3/.error &
  done

  wait
  [ -f exp/nnet3/.error ] && echo "$0: error extracting iVectors." && exit 1;
fi

exit 0;
