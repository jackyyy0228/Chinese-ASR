#!/bin/bash
fbankdir=data/fbank

. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh
set -euo pipefail
noise_dir=data/kgb_noise

for corpus in cyberon_chinese_test TOCFL train_sp ; do
  data=data/$corpus/fbank
  data_aug=data/$corpus\_aug_kgb_noise/fbank
  if [ ! -f $data/reco2dur ] ; then
    bash utils/data/get_reco2utt.sh $data || exit 1
  fi
  
  if [ ! -f $noise_dir ] ; then
    bash utils/data/get_reco2utt.sh $noise_dir || exit 1
  fi

  python2 steps/data/augment_data_dir.py --utt-suffix aug_kgb_noise --bg-snrs 9:7:5 --num-bg-noises 1 --bg-noise-dir $noise_dir $data $data_aug

  name=$corpus\_aug_kgb_noise
  steps/make_fbank.sh --nj 50 --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $name $data_aug exp/make_fbank/$name $fbankdir
  steps/compute_cmvn_stats.sh --name $name $data_aug exp/make_fbank/$name $fbankdir


  rm -rf ./data/$corpus\_rvb_aug/fbank
  utils/combine_data.sh ./data/$corpus\_aug_kgb_noise_ori/fbank $data_aug $data 
done

ali_src=exp/tri4a_sp_ali
ali_target=exp/tri4a_sp_aug_kgb_noise_ali
rm -r $ali_target
cp -r $ali_src $ali_target
local/nnet/copy_alignment.sh $ali_target

ali_src=exp/tri4a_ali_cyberon_chinese_test
ali_target=exp/tri4a_ali_cyberon_chinese_test_aug_kgb_noise

rm -r $ali_target
cp -r $ali_src $ali_target
local/nnet/copy_alignment.sh $ali_target
