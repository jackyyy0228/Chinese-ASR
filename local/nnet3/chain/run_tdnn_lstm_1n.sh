#!/bin/bash


# 1n is as 1m but with significant changes, replacing TDNN layers with a
# structure like run_tdnn_7n.sh.  Seems better!  But the improvement
# versus the best TDNN system (see run_tdnn_7n.sh) is so small that it's
# not really worth it when you consider how much slower it is.

# local/chain/compare_wer_general.sh --rt03 tdnn_lstm_1m_ld5_sp tdnn_lstm_1m_ld5_sp_online tdnn_lstm1n_sp tdnn_lstm1n_sp_online
# System                tdnn_lstm_1m_ld5_sp tdnn_lstm_1m_ld5_sp_online tdnn_lstm1n_sp tdnn_lstm1n_sp_online
# WER on train_dev(tg)      12.33     12.21     12.38     12.49
# WER on train_dev(fg)      11.42     11.41     11.48     11.59
# WER on eval2000(tg)        15.2      15.1      15.0      14.9
# WER on eval2000(fg)        13.8      13.8      13.5      13.5
# WER on rt03(tg)            18.6      18.4      18.0      18.0
# WER on rt03(fg)            16.3      16.1      15.8      15.8
# Final train prob         -0.082     0.000    -0.084     0.000
# Final valid prob         -0.099     0.000    -0.104     0.000
# Final train prob (xent)        -0.959     0.000    -1.154     0.000
# Final valid prob (xent)       -1.0305    0.0000   -1.2190    0.0000
# Num-parameters               39558436         0  27773348         0
#


# exp/chain/tdnn_lstm1n_sp: num-iters=394 nj=3..16 num-params=27.8M dim=40+100->6034 combine=-0.081->-0.080 (over 5) xent:train/valid[261,393,final]=(-1.59,-1.14,-1.15/-1.64,-1.22,-1.22) logprob:train/valid[261,393,final]=(-0.105,-0.086,-0.084/-0.123,-0.107,-0.104)

set -e

# configs for 'chain'
stage=0
train_stage=-10
get_egs_stage=-10
speed_perturb=true
affix=1n
decode_iter=
decode_dir_affix=
decode_nj=50
if [ -e data/rt03 ]; then maybe_rt03=rt03; else maybe_rt03= ; fi

# training options
frames_per_chunk=140,100,160
frames_per_chunk_primary=$(echo $frames_per_chunk | cut -d, -f1)
chunk_left_context=40
chunk_right_context=0
xent_regularize=0.025
self_repair_scale=0.00001
label_delay=5
# decode options
extra_left_context=50
extra_right_context=0
dropout_schedule='0,0@0.20,0.3@0.50,0'

remove_egs=true
common_egs_dir=

test_online_decoding=true  # if true, it will run the last decoding stage.
# End configuration section.
echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

# The iVector-extraction and feature-dumping parts are the same as the standard
# nnet3 setup, and you can skip them by setting "--stage 8" if you have already
# run those things.

suffix=
if [ "$speed_perturb" == "true" ]; then
  suffix=_sp
fi

dir=exp/chain/tdnn_lstm${affix}${suffix}
train_set=train_no_eng_sp/mfcc40_pitch3
test_sets="TOCFL cyberon_chinese_test"
train_ivector_dir=exp/nnet3/ivectors_train_no_eng_sp
ali_dir=exp/tri4_ali_nodup$suffix
treedir=exp/chain/tri5_7d_tree$suffix
lang=data/lang


# if we are using the speed-perturbed data we need to generate
# alignments for it.


if [ $stage -le 9 ]; then
  # Get the alignments as lattices (gives the CTC training more freedom).
  # use the same num-jobs as the alignments
  steps/align_fmllr_lats.sh --nj 8 --cmd "$train_cmd" data/train_no_eng_sp/mfcc39_pitch9 \
    data/lang exp/tri4a exp/tri4_lats_nodup$suffix
  rm exp/tri4_lats_nodup$suffix/fsts.*.gz # save space
fi


if [ $stage -le 10 ]; then
  # Create a version of the lang/ directory that has one state per phone in the
  # topo file. [note, it really has two states.. the first one is only repeated
  # once, the second one has zero or more repeats.]
  rm -rf $lang
  cp -r data/lang $lang
  silphonelist=$(cat $lang/phones/silence.csl) || exit 1;
  nonsilphonelist=$(cat $lang/phones/nonsilence.csl) || exit 1;
  # Use our special topology... note that later on may have to tune this
  # topology.
  steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$lang/topo
fi

if [ $stage -le 11 ]; then
  # Build a tree using our new topology.
  steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 \
      --context-opts "--context-width=2 --central-position=1" \
      --cmd "$train_cmd" 7000 data/$train_set $lang $ali_dir $treedir
fi

if [ $stage -le 12 ]; then
  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $treedir/tree |grep num-pdfs|awk '{print $2}')
  learning_rate_factor=$(echo "print 0.5/$xent_regularize" | python)

  opts="l2-regularize=0.002"
  linear_opts="orthonormal-constraint=1.0"
  lstm_opts="l2-regularize=0.0005 decay-time=40"
  output_opts="l2-regularize=0.0005 output-delay=$label_delay max-change=1.5 dim=$num_targets"


  mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig
  input dim=100 name=ivector
  input dim=43 name=input

  fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat

  # the first splicing is moved before the lda layer, so no splicing here
  relu-batchnorm-layer name=tdnn1 $opts dim=1280
  linear-component name=tdnn2l dim=256 $linear_opts input=Append(-1,0)
  relu-batchnorm-layer name=tdnn2 $opts input=Append(0,1) dim=1280
  linear-component name=tdnn3l dim=256 $linear_opts
  relu-batchnorm-layer name=tdnn3 $opts dim=1280
  linear-component name=tdnn4l dim=256 $linear_opts input=Append(-1,0)
  relu-batchnorm-layer name=tdnn4 $opts input=Append(0,1) dim=1280
  linear-component name=tdnn5l dim=256 $linear_opts
  relu-batchnorm-layer name=tdnn5 $opts dim=1280 input=Append(tdnn5l, tdnn3l)
  linear-component name=tdnn6l dim=256 $linear_opts input=Append(-3,0)
  relu-batchnorm-layer name=tdnn6 $opts input=Append(0,3) dim=1280
  linear-component name=lstm1l dim=256 $linear_opts input=Append(-3,0)
  fast-lstmp-layer name=lstm1 cell-dim=1024 recurrent-projection-dim=256 non-recurrent-projection-dim=128 delay=-3 dropout-proportion=0.0 $lstm_opts
  relu-batchnorm-layer name=tdnn7 $opts input=Append(0,3,tdnn6l,tdnn4l,tdnn2l) dim=1280
  linear-component name=tdnn8l dim=256 $linear_opts input=Append(-3,0)
  relu-batchnorm-layer name=tdnn8 $opts input=Append(0,3) dim=1280
  linear-component name=lstm2l dim=256 $linear_opts input=Append(-3,0)
  fast-lstmp-layer name=lstm2 cell-dim=1280 recurrent-projection-dim=256 non-recurrent-projection-dim=128 delay=-3 dropout-proportion=0.0 $lstm_opts
  relu-batchnorm-layer name=tdnn9 $opts input=Append(0,3,tdnn8l,tdnn6l,tdnn4l) dim=1280
  linear-component name=tdnn10l dim=256 $linear_opts input=Append(-3,0)
  relu-batchnorm-layer name=tdnn10 $opts input=Append(0,3) dim=1280
  linear-component name=lstm3l dim=256 $linear_opts input=Append(-3,0)
  fast-lstmp-layer name=lstm3 cell-dim=1280 recurrent-projection-dim=256 non-recurrent-projection-dim=128 delay=-3 dropout-proportion=0.0 $lstm_opts

  output-layer name=output input=lstm3  include-log-softmax=false $output_opts

  output-layer name=output-xent input=lstm3 learning-rate-factor=$learning_rate_factor $output_opts
EOF
  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi

if [ $stage -le 13 ]; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
      /export/c0{1,2,5,7}/$USER/kaldi-data/egs/swbd-$(date +'%m_%d_%H_%M')/s5c/$dir/egs/storage $dir/egs/storage
  fi

  steps/nnet3/chain/train.py --stage $train_stage \
    --cmd "$decode_cmd" \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.0 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.dropout-schedule $dropout_schedule \
    --trainer.num-chunk-per-minibatch 64,32 \
    --trainer.frames-per-iter 1500000 \
    --trainer.max-param-change 2.0 \
    --trainer.num-epochs 6 \
    --trainer.optimization.num-jobs-initial 2 \
    --trainer.optimization.num-jobs-final 2 \
    --trainer.optimization.initial-effective-lrate 0.001 \
    --trainer.optimization.final-effective-lrate 0.0001 \
    --trainer.optimization.momentum 0.0 \
    --trainer.deriv-truncate-margin 8 \
    --egs.stage $get_egs_stage \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width $frames_per_chunk \
    --egs.chunk-left-context $chunk_left_context \
    --egs.chunk-right-context $chunk_right_context \
    --egs.chunk-left-context-initial 0 \
    --egs.chunk-right-context-final 0 \
    --egs.dir "$common_egs_dir" \
    --cleanup.remove-egs $remove_egs \
    --feat-dir data/${train_set} \
    --tree-dir $treedir \
    --lat-dir exp/tri4_lats_nodup$suffix \
    --dir $dir  || exit 1;
fi

if [ $stage -le 14 ]; then
  # Note: it might appear that this $lang directory is mismatched, and it is as
  # far as the 'topo' is concerned, but this script doesn't read the 'topo' from
  # the lang directory.
  utils/mkgraph.sh --self-loop-scale 1.0 data/lang $dir $dir/graph
fi

if [ $stage -le 14 ]; then
  rm $dir/.error 2>/dev/null || true
  for affix in $test_sets ; do
    test_ivector_dir=exp/nnet3/ivectors_$affix
    graph_dir=$dir/graph                                     
    
    startt=`date +%s`
    echo $startt 
    steps/nnet3/decode_looped.sh \
      --frames-per-chunk 30 \
      --nj 12 --cmd "$decode_cmd" \
      --online-ivector-dir $test_ivector_dir \
      $graph_dir data/$affix/mfcc40_pitch3 ${dir}/decode_looped_3small_${affix} || exit 1
    
    endt=`date +%s`
    runtime=$((endt-startt))
    echo "Decode_loop time of $affix: $runtime"
    
    startt=`date +%s`
    steps/lmrescore.sh --cmd "$decode_cmd" data/lang_3{small,mid}_test \
      data/$affix/mfcc40_pitch3 ${dir}/decode_looped_3{small,mid}_$affix || exit 1
    
    endt=`date +%s`
    runtime=$((endt-startt))
    echo "Decode_loop rescoring time of $affix: $runtime"
    
    startt=`date +%s`
    steps/lmrescore.sh --cmd "$decode_cmd" data/lang_{3mid,4large}_test \
      data/$affix/mfcc40_pitch3 ${dir}/decode_looped_{3mid,4large}_$affix || exit 1
    
    endt=`date +%s`
    runtime=$((endt-startt))
    echo "Decode_loop rescoring time of $affix: $runtime"
  done                                                                       
fi
