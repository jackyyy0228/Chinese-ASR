. ./path.sh
. ./cmd.sh

. utils/parse_options.sh || exit 1;

set -e
set -u
set -o pipefail
#########################
dnn_model=$1
visible_gpu=$2
export CUDA_VISIBLE_DEVICES=$visible_gpu
stage=3

#####CE-training
lrate=0.00001
suffix=

dir=exp/nnet/aishell2/tri4a_${dnn_model}_aug_ori2

train_data=data/train_sp_aishell_for_train_aug_ori/fbank
train_ali=exp/tri4a_train_sp_aishell_for_train_aug_ori_ali
dev_data=data/train_sp_aishell_for_dev_aug_ori/fbank
dev_ali=exp/tri4a_train_sp_aishell_for_dev_aug_ori_ali

mkdir -p $dir

if [ $stage -le 3 ]; then
    proto=local/nnet/${dnn_model}.proto
    ori_num_pdf=`cat $proto |grep "Softmax" |awk '{print $3}'`
    echo $ori_num_pdf
    new_num_pdf=`gmm-info ./exp/aishell2/tri4_ali_train_sp_aug/final.mdl | grep "number of pdfs" |awk '{print $4}'`
    echo $new_num_pdf
    new_proto=${proto}.$new_num_pdf
    sed -r "s/"$ori_num_pdf"/"$new_num_pdf"/g" $proto > $new_proto

    $cuda_cmd $dir/_train_nnet.log \
        steps/nnet/train_faster.sh --learn-rate $lrate --nnet-proto $new_proto \
        --start_half_lr 10 --momentum 0.9 \
        --train-tool "nnet-train-fsmn-streams" \
        --feat-type plain --splice 1 \
        --cmvn-opts "--norm-means=true --norm-vars=false" --delta_opts "--delta-order=2" \
        --train-tool-opts "--minibatch-size=4096" \
        --split_feats 10 \
        --learn_rate 1e-5 \
        $train_data $dev_data \
        data/lang $train_ali $dev_ali $dir
    
fi
####Decode
acwt=0.08
#suffix=aug_kgb_noise_ori
if [ $stage -le 4  ]; then
        gmm=exp/aishell2/tri4_taiwanese
        dataset="TOCFL cyberon_chinese_test  aishell2_dev_aug"
        for set in $dataset
        do
             startt=`date +%s`
             steps/nnet/decode.sh --nj 12 --cmd "$decode_cmd" \
                 --acwt $acwt \
                 $gmm/graph \
                 ./data/$set/fbank $dir/decode_3small_${set}
             endt=`date +%s`
             runtime=$((endt-startt))
             echo "Decode time of 3small: $runtime"
             
             startt=`date +%s`
             steps/lmrescore.sh --cmd "$decode_cmd" data/lang_{3small,3mid}_test \
                 ./data/$set/fbank $dir/decode_{3small,3mid}_${set}
             endt=`date +%s`
             runtime=$((endt-startt))
             echo "rescoring time of 3mid: $runtime"

             startt=`date +%s`
             steps/lmrescore.sh \
                 --cmd "$decode_cmd" data/lang_{3small,4large}_test \
                 ./data/$set/fbank $dir/decode_{3small,4large}_${set}
             endt=`date +%s`
             runtime=$((endt-startt))
             echo "rescoring time of 4large: $runtime"
        done
fi
