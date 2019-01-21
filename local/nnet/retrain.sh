. ./path.sh
. ./cmd.sh

set -e
set -u
set -o pipefail

. utils/parse_options.sh || exit 1;


data=data/train_sp_aug/fbank
ali=exp/aishell2/tri4_ali_train_sp_aug  
dnn_model=$1
oridir=$2
visible_gpu=$3

export CUDA_VISIBLE_DEVICES=$visible_gpu

#########################
stage=2
nj=10

dir=$oridir\_train_more

lrate=1.95313e-08
mlp_init=$(cat $oridir/.mlp_best)

if [ $stage -le 3 ]; then
    proto=local/nnet/${dnn_model}.proto
    ori_num_pdf=`cat $proto |grep "Softmax" |awk '{print $3}'`
    echo $ori_num_pdf
    new_num_pdf=`gmm-info ./exp/aishell2/tri4_ali_train_sp_aug/final.mdl | grep "number of pdfs" |awk '{print $4}'`
    echo $new_num_pdf
    new_proto=${proto}.$new_num_pdf
    sed -r "s/"$ori_num_pdf"/"$new_num_pdf"/g" $proto > $new_proto

    $cuda_cmd $dir/_train_nnet.log \
        local/nnet/train_more.sh --learn-rate $lrate --nnet-proto $new_proto \
        --start_half_lr 10 --momentum 0.9 \
        --train-tool "nnet-train-fsmn-streams" \
        --feat-type plain --splice 1 \
        --cmvn-opts "--norm-means=true --norm-vars=false" --delta_opts "--delta-order=2" \
        --train-tool-opts "--minibatch-size=4096" \
        --max_iters 7 \
        --split_feats 7 \
        $mlp_init $data data/lang $ali $dir
fi
