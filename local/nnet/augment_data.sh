#!/bin/bash
fbankdir=data/fbank

. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh
set -euo pipefail


for corpus in cyberon_chinese_test TOCFL train_sp ; do
  data=data/$corpus/fbank
  data_aug=data/$corpus\_aug/fbank
  data_rvb=data/$corpus\_rvb/fbank
  if [ ! -f $data/reco2dur ] ; then
    bash utils/data/get_reco2utt.sh $data || exit 1
  fi

  python2 steps/data/augment_data_dir.py --utt-suffix aug --bg-snrs 20:10:5:3:0 --num-bg-noises 1:2 --bg-noise-dir data/noise $data $data_aug
  python2 steps/data/reverberate_data_dir.py --prefix rvb --speech-rvb-probability 1 --num-replications 1 \
    --rir-set-parameters data/RIRS_NOISES/simulated_rirs/smallroom/rir_list $data $data_rvb

  name=$corpus\_aug
  steps/make_fbank.sh --nj 50 --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $name $data_aug exp/make_fbank/$name $fbankdir
  steps/compute_cmvn_stats.sh --name $name $data_aug exp/make_fbank/$name $fbankdir

  name=$corpus\_rvb
  steps/make_fbank.sh --nj 50 --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $name $data_rvb exp/make_fbank/$name $fbankdir
  steps/compute_cmvn_stats.sh --name $name $data_rvb exp/make_fbank/$name $fbankdir

  rm -rf ./data/$corpus\_rvb_aug/fbank
  utils/combine_data.sh ./data/$corpus\_rvb_aug/fbank $data_aug $data_rvb $data 
done

rm -r exp/tri4a_sp_rvb_aug_ali
cp -r exp/tri4a_sp_ali exp/tri4a_sp_rvb_aug_ali
local/nnet/copy_alignment.sh exp/tri4a_sp_rvb_aug_ali/

rm -r exp/tri4a_ali_cyberon_chinese_test_rvb_aug
cp -r exp/tri4a_ali_cyberon_chinese_test exp/tri4a_ali_cyberon_chinese_test_rvb_aug
local/nnet/copy_alignment.sh exp/tri4a_ali_cyberon_chinese_test_rvb_aug

