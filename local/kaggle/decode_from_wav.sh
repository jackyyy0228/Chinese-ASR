#!/bin/bash
. ./path.sh
. ./cmd.sh
set -e
set -u
set -o pipefail

use_gpu="no" # yes|no|optionaly

nnet=               # non-default location of DNN (optional)
feature_transform=  # non-default location of feature_transform (optional)
model=              # non-default location of transition model (optional)
graph=exp/tri4a/graph_wfst
acwt=0.08
rescore=true
rescore_lang=data/lang_4large_test
rescore_arpa=false
stage=0
beam=13
max_active=7000
lattice_beam=8
fbank_nj=50
decode_nj=50
choose_lm=false
num_threads=1
n_best=1
mode=4 # mode for lmrescoring

. ./utils/parse_options.sh
echo $@
if [ $# != 3 ]; then
   echo "Usage: $0 [options] <wav-dir> <nnet-dir> <decode-dir> "
   echo "main options (for others, see top of script file)"
   echo "  --config <config-file>                           # config containing options"
   echo "  --fbank_nj <nj>                                  # number of parallel jobs of extracting fbank"
   echo "  --decode_nj <nj>                                  # number of parallel jobs of decoding"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   echo ""
   echo "  --nnet <nnet>                                    # non-default location of DNN (opt.)"
   echo "  --graph <nnet>                                   # non-default location of GMM graph (opt.)"
   echo "                                                   # default exp/tri4a "
   echo ""
   echo "  --acwt <float>                                   # select acoustic scale for decoding"
   echo "  --use_gpu <yes|no|optional>                     # decode nnet using gpu (default yes)"
   exit 1;
fi

wav_dir=$1
nnet_dir=$2
dir=$3

decode_opts=""
[ -z "$graph" ] && graph=exp/tri4a/graph_mix 
[ ! -z "$nnet" ] && decode_opts="$decode_opts --nnet $nnet" 

data_dir=$dir/data
if [ $stage -le 0 ]; then
  local/data/data_prep_wav.sh $wav_dir $data_dir
fi

if [ $stage -le 1 ]; then
  utils/fix_data_dir.sh $data_dir
  name=`basename $dir`
  steps/make_fbank.sh --nj $fbank_nj --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $name \
      $data_dir $data_dir/make_fbank $data_dir/fbank
  steps/compute_cmvn_stats.sh --name $name $data_dir $data_dir/make_fbank $data_dir/fbank
fi

if [ $stage -le 2 ]; then
   startt=`date +%s`
   steps/nnet/decode.sh --nj $decode_nj --cmd "$decode_cmd" --beam $beam --max_active $max_active --num-threads $num_threads\
      --acwt $acwt --srcdir $nnet_dir --use_gpu $use_gpu --skip_scoring true --lattice_beam $lattice_beam \
      $decode_opts $graph $data_dir $dir/decode_3small
   local/lattice_to_text.sh --n_best $n_best $graph $dir/decode_3small  
   cp $dir/decode_3small/output.txt $dir/output.txt
   
   endt=`date +%s`
   runtime=$((endt-startt))
   echo "Decode time of 3small: $runtime" > $dir/3small_time
   output=`cat $dir/output.txt | cut -d' ' -f2-`
   
   if [[  -z "${output// }" ]] ; then
     ## output is empty
     echo "The output of $dir is empty."
     exit 1 
   fi

   if $choose_lm ; then
     for lm in ori news 20years nie guan laotsan water journey_west red_mansion 3kingdom beauty_n hunghuang lai_ho old_time one_gan lu_shun ; do
        echo $lm >> $dir/lm_score
        cat $dir/output.txt | cut -d' ' -f2- |  ngram -lm lm_test/LM/$lm\_A.lm -ppl - | python3 local/kaggle/get_ppl.py - >> $dir/lm_score
     done
     lm=`python3 local/kaggle/max_ppl.py 0 $dir/lm_score 1`
     rescore_lang=lm_test/LM/$lm\_A
     echo $rescore_lang > $dir/rescore_lang_3small
     wav=`basename $dir`
     python3 local/kaggle/max_ppl.py $wav\.wav $dir/lm_score 3 > $dir/lm
   fi
fi
if [ $stage -le 3 ]; then
   if $rescore ; then
     startt=`date +%s`
     if $rescore_arpa ; then
       steps/lmrescore_const_arpa_undeterminized.sh \
         --cmd "$decode_cmd" --skip_scoring true data/lang_3small_test  $rescore_lang \
         $data_dir $dir/decode_3small $dir/decode_rescore
     else
       cp $nnet_dir/final.mdl $dir/
       steps/lmrescore2.sh \
           --mode $mode \
           --cmd "$decode_cmd" --skip_scoring true data/lang_3small_test  $rescore_lang \
           $data_dir $dir/decode_3small $dir/decode_rescore
     fi
     local/lattice_to_text.sh --n_best $n_best $graph $dir/decode_rescore
     cp $dir/decode_rescore/output.txt $dir/output.txt
     endt=`date +%s`
     runtime=$((endt-startt))
     echo "rescoring time of 4large: $runtime" > $dir/rescore_time
   fi
fi

echo "Done $dir."
exit 0;


