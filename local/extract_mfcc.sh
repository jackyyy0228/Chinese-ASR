#!/bin/bash
nj=8 #number of job parallel running
stage=0
. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh


if [ $stage -le 1 ] ; then
  mfccdir=data/mfcc_pitch
  mfcc_pitch_hires_dir=data/mfcc_pitch_hires
  mfcc_hires_dir=data/mfcc_hires

  mkdir -p $mfccdir
  mkdir -p $mfcc_pitch_hires_dir
  mkdir -p $mfcc_hires_dir

  for corpus in cyberon_chinese_train cyberon_english_train cyberon_chinese_test cyberon_english_test PTS NER TOCFL seame Tl MATBN ; do
    ##Extract MFCC39 + pitch9 feature
    data=./data/$corpus/mfcc39_pitch9
    steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh --name $corpus $data exp/make_mfcc/$corpus $mfccdir || exit 1;
    if [ $corpus = seame ] || [ $corpus = MATBN ] ; then
      PYTHONIOENCODING=utf-8 python3 local/data/fix_segments.py $data
    fi
    ##Extract MFCC40 + pitch3 feature
    data=./data/$corpus/mfcc40_pitch3
    utils/copy_data_dir.sh data/$corpus/mfcc39_pitch9 $data

    ## Volumn Perturbation
    cat $data/wav.scp | python2 -c "
import sys, os, subprocess, re, random
scale_low = 1.0/8
scale_high = 2.0
for line in sys.stdin.readlines():
  if len(line.strip()) == 0:
    continue
  if line.strip().endswith('|'):
    print '{0} sox --vol {1} -t wav - -t wav - |'.format(line.strip(), random.uniform(scale_low, scale_high))
  else:
    label, wav_file = line.split()
    print '{0} sox --vol {2} -t wav {1} -t wav - |'.format(label,wav_file,random.uniform(scale_low, scale_high))
"| sort -k1,1 -u  > $data/wav.scp_scaled || exit 1;
     mv $data/wav.scp $data/wav.scp_nonorm
     mv $data/wav.scp_scaled $data/wav.scp
    
    steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj --mfcc-config conf/mfcc_hires.conf  --name $corpus \
      $data exp/make_hires/$corpus $mfcc_pitch_hires_dir || exit 1;
    steps/compute_cmvn_stats.sh --name $corpus $data exp/make_pitch_hires/$corpus $mfcc_pitch_hires_dir || exit 1;

    # create MFCC data dir without pitch to extract iVector
    utils/data/limit_feature_dim.sh 0:39 $data data/$corpus/mfcc40 || exit 1;
    steps/compute_cmvn_stats.sh --name $corpus  data/$corpus/mfcc40 exp/make_hires/$corpus $mfcc_hires_dir || exit 1;
  done
fi
if [ $stage -le 2 ] ; then
  combine48=''
  combine43=''
  combine40=''
  for corpus in cyberon_chinese_train cyberon_english_train PTS NER TOCFL seame Tl MATBN ; do
    data=./data/$corpus/mfcc39_pitch9
    combine48="$data $combine48"
    data=./data/$corpus/mfcc40_pitch3
    combine43="$data $combine43"
    data=./data/$corpus/mfcc40
    combine40="$data $combine40"
  done
  utils/combine_data.sh data/train/mfcc39_pitch9 $combine48
  utils/combine_data.sh data/train/mfcc40_pitch3 $combine43
  utils/combine_data.sh data/train/mfcc40 $combine40

  # make no english audio dataset (only english alphabet and numbers)
  combine48=''
  combine43=''
  combine40=''
  for corpus in cyberon_chinese_train PTS NER Tl MATBN ; do
    data=./data/$corpus/mfcc39_pitch9
    combine48="$data $combine48"
    data=./data/$corpus/mfcc40_pitch3
    combine43="$data $combine43"
    data=./data/$corpus/mfcc40
    combine40="$data $combine40"
  done
  utils/combine_data.sh data/train_no_eng/mfcc_39_pitch9 $combine48
  utils/combine_data.sh data/train_no_eng/mfcc_40_pitch3 $combine43
  utils/combine_data.sh data/train_no_eng/mfcc40 $combine40
fi
