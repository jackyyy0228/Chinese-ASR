#!/bin/bash

# Copyright 2012-2017  Brno University of Technology (author: Karel Vesely)
# Apache 2.0

# Schedules epochs and controls learning rate during the neural network training

# Begin configuration.

# training options,
learn_rate=0.008
momentum=0
l1_penalty=0
l2_penalty=0

# data processing,
train_tool="nnet-train-frmshuff"
train_tool_opts=""
feature_transform=

split_feats= # int -> number of splits 'feats.scp -> feats.${i}.scp', starting from feats.1.scp,
             # (data are alredy shuffled and split to N parts),
             # empty -> no splitting,

# learn rate scheduling,
max_iters=4
min_iters=0 # keep training, disable weight rejection, start learn-rate halving as usual,
keep_lr_iters=0 # fix learning rate for N initial epochs, disable weight rejection,
dropout_schedule= # dropout-rates for N initial epochs, for example: 0.1,0.1,0.1,0.1,0.1,0.0
start_halving_impr=0.001
end_halving_impr=0.0001
halving_factor=0.5
start_half_lr=5 
randseed=777


# misc,
verbose=0 # 0 No GPU time-stats, 1 with GPU time-stats (slower),
frame_weights=
utt_weights=

# End configuration.

echo "$0 $@"  # Print the command line for logging
[ -f path.sh ] && . ./path.sh;

. parse_options.sh || exit 1;

set -euo pipefail

if [ $# != 4 ]; then
   echo "Usage: $0 <mlp-now> <feats-tr> <labels-tr> <exp-dir>"
   echo " e.g.: $0 0.nnet scp:train.scp ark:labels_tr.ark  exp/dnn1"
   echo "main options (for others, see top of script file)"
   echo "  --config <config-file>  # config containing options"
   exit 1;
fi

mlp_now=$1
feats_tr=$2
labels_tr=$3
dir=$4
echo "max_iter: $max_iters"

dropout_array=($(echo ${dropout_schedule} | tr ',' ' '))

##############################
# start training

# choose mlp to start with,

# optionally resume training from the best epoch, using saved learning-rate,


# training,
for iter in $(seq -w $max_iters); do
  echo -n "ITERATION $iter: "

  # shuffle train.scp
  cat $dir/train.scp | utils/shuffle_list.pl --srand ${seed:-${randseed}} > $dir/train.scp.iter$iter
  rm $dir/train.scp
  mv $dir/train.scp.iter$iter $dir/train.scp

  mlp_next=${mlp_now}_train_more_iter${iter}


  # set dropout-rate from the schedule,
  if [ -n ${dropout_array[$((${iter#0}-1))]-''} ]; then
    dropout_rate=${dropout_array[$((${iter#0}-1))]}
    nnet-copy --dropout-rate=$dropout_rate $mlp_best ${mlp_best}.dropout_rate${dropout_rate}
    mlp_best=${mlp_best}.dropout_rate${dropout_rate}
  fi

  # select the split,
  feats_tr_portion="$feats_tr" # no split?
  if [ -n "$split_feats" ]; then
    portion=$((1 + iter % split_feats))
    feats_tr_portion="${feats_tr/train.scp/train.${portion}.scp}"
  fi

  # training,
  log=$dir/log/iter${iter}_train_more.tr.log; hostname>$log
  $train_tool --cross-validate=false --randomize=true --verbose=$verbose $train_tool_opts \
    --learn-rate=$learn_rate --momentum=$momentum \
    --l1-penalty=$l1_penalty --l2-penalty=$l2_penalty \
    ${feature_transform:+ --feature-transform=$feature_transform} \
    ${frame_weights:+ "--frame-weights=$frame_weights"} \
    ${utt_weights:+ "--utt-weights=$utt_weights"} \
    "$feats_tr_portion" "$labels_tr" $mlp_now $mlp_next \
    2>> $log || exit 1;

  tr_loss=$(cat $dir/log/iter${iter}_train_more.tr.log | grep "AvgLoss:" | tail -n 1 | awk '{ print $4; }')
  echo -n "TRAIN AVG.LOSS $(printf "%.4f" $tr_loss), (lrate$(printf "%.6g" $learn_rate)), "
done

