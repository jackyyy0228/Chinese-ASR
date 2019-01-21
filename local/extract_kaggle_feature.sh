#$!/bin/bash
nj=8 #number of job parallel running
stage=0
. ./path.sh
. ./cmd.sh
. ./utils/parse_options.sh


if [ $stage -le 1 ] ; then
  mfccdir=data/mfcc_pitch
  mkdir -p $mfccdir

  for corpus in kaggle1 kaggle2 kaggle3 ; do
    combine48=''
    for typ in A B C ; do
      ##Extract MFCC39 + pitch9 feature
      data=./data/$corpus/$typ/mfcc39_pitch9
      name=$corpus\_$typ
      combine48="$data $combine48"
      steps/make_mfcc_pitch_online.sh --cmd "$train_cmd" --nj $nj --name $name $data exp/make_mfcc/$name $mfccdir || exit 1;
      steps/compute_cmvn_stats.sh --name $name $data exp/make_mfcc/$name $mfccdir || exit 1;
    done
    utils/combine_data.sh ./data/$corpus/mfcc39_pitch9 $combine48 
  done
fi

if [ $stage -le 1 ] ; then
  fbankdir=data/fbank
  mkdir -p $fbankdir

  for corpus in kaggle1 kaggle2 kaggle3 ; do
    combine48=''
    for typ in A B C ; do
      mfccdata=./data/$corpus/$typ/mfcc39_pitch9
      data=./data/$corpus/$typ/fbank
      name=$corpus\_$typ
      combine48="$data $combine48"
      
      utils/copy_data_dir.sh $mfccdata $data
      steps/make_fbank.sh --nj 30 --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $name \
          $data exp/make_fbank/$name $fbankdir
      steps/compute_cmvn_stats.sh --name $name $data exp/make_fbank/$name $fbankdir
    done
    utils/combine_data.sh ./data/$corpus/fbank $combine48 
  done
fi
