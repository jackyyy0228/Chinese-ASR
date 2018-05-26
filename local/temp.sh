#!bin/bash
. ./path.sh
. ./cmd.sh

datadir=./data/CyberonChinese
stage=5


if [ $stage -le 1 ]; then
  #data_prep
  local/data_prep_cyberon.sh
fi

if [ $stage -le 2 ]; then
  #prepare dictionary lexicon
  local/prepare_ch_dict.sh
  # Phone Sets, questions, L compilation                                                                                                      
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
  # LM training
  local/hkust_train_lms.sh
  #G compilation, check LG composition
  local/hkust_format_data.sh
fi


#extract spectrogram
if [ $stage -le 3 ]; then
  specdir=data/spectrogram
  x=CyberonChinese
  compute-spectrogram-feats --allow_downsample=true scp,p:$datadir/wav.scp ark,t:$specdir/$x.ark
fi
# make mfcc
if [ $stage -le 4 ]; then
  mfccdir=data/mfcc
  x=CyberonChinese
  steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj 8   $datadir exp/make_mfcc/$x $mfccdir || exit 1;
  steps/compute_cmvn_stats.sh $datadir exp/make_mfcc/$x $mfccdir || exit 1;
fi
if [ $stage -le 5 ]; then




