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
if [ $stage -le 0 ]; then
    min_seg_len=1.55
    train_set=train_960_cleaned
    gmm=tri6b_cleaned
    nnet3_affix=_cleaned
    local/nnet3/run_ivector_common.sh --stage $stage \
                                   --min-seg-len $min_seg_len \
                                   --train-set $train_set \
                                   --gmm $gmm \
                                   --num-threads-ubm 6 --num-processes 3 \
                                   --nnet3-affix "$nnet3_affix" || exit 1;
fi

##Make fbank features
if [ $stage -le 1 ]; then
    mkdir -p data_fbank
    for x in train_960_cleaned test_other test_clean dev_other dev_clean; do
        fbankdir=fbank/$x
        cp -r data/$x data_fbank/$x
        steps/make_fbank.sh --nj 30 --cmd "$train_cmd"  --fbank-config conf/fbank.conf \
            data_fbank/$x exp/make_fbank/$x $fbankdir
        steps/compute_cmvn_stats.sh data_fbank/$x exp/make_fbank/$x $fbankdir
    done
fi
###############
if [ $stage -le 2 ]; then
    steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
        data/train_960_cleaned data/lang exp/tri6b_cleaned exp/tri6b_cleaned_ali_train_960_cleaned
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
        data/dev_clean data/lang exp/tri6b_cleaned exp/tri6b_cleaned_ali_dev_clean
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
        data/dev_other data/lang exp/tri6b_cleaned exp/tri6b_cleaned_ali_dev_other
fi
#####CE-training
lrate=0.00001
dir=exp/nnet/tri4a_${dnn_model}_woiv
if [ $stage -le 3 ]; then
    proto=local/nnet/${dnn_model}.proto
    ori_num_pdf=`cat $proto |grep "Softmax" |awk '{print $3}'`
    echo $ori_num_pdf
    new_num_pdf=`gmm-info ./exp/tri4a/final.mdl |grep "number of pdfs" |awk '{print $4}'`
    echo $new_num_pdf
    new_proto=${proto}.$new_num_pdf
    sed -r "s/"$ori_num_pdf"/"$new_num_pdf"/g" $proto > $new_proto

    $cuda_cmd $dir/_train_nnet.log \
        steps/nnet/train_faster.sh --learn-rate $lrate --nnet-proto $new_proto \
        --start_half_lr 5 --momentum 0.9 \
        --train-tool "nnet-train-fsmn-streams" \
        --feat-type plain --splice 1 \
        --cmvn-opts "--norm-means=true --norm-vars=false" --delta_opts "--delta-order=2" \
        --train-tool-opts "--minibatch-size=4096" \
        data/train_sp/fbank data/cyberon_chinese_test/fbank data/lang exp/tri4a_sp_ali exp/tri4a_ali_cyberon_chinese_test $dir
fi
####Decode
acwt=0.08
if [ $stage -le 4  ]; then
        gmm=exp/tri4a
        dataset="TOCFL cyberon_chinese_test"
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
             steps/lmrescore_const_arpa.sh \
                 --cmd "$decode_cmd" data/lang_{3small,4large}_test \
                 ./data/$set/fbank $dir/decode_{3small,4large}_${set}
             endt=`date +%s`
             runtime=$((endt-startt))
             echo "rescoring time of 4large: $runtime"
        done
fi
#gen ali & lat for smbr
nj=10
if [ $stage -le 5 ]; then
        steps/nnet/align.sh --nj $nj --cmd "$train_cmd" --use_gpu 'yes' \
            data/train_sp/fbank data/lang $dir ${dir}_ali
        steps/nnet/make_denlats.sh --nj $nj --cmd "$decode_cmd" --acwt $acwt \
            --ivector scp:exp/nnet3/ivectors_train_sp_cyberon_chinese/ivector_online.scp \
            --ivector-append-tool "append-ivector-to-feats --online-ivector-period=10" \
            data/train_sp/fbank data/lang $dir ${dir}_denlats
fi

####do smbr
if [ $stage -le 5 ]; then
        steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 2 --learn-rate 0.0000002 --acwt $acwt --do-smbr true \
            data/train_sp/fbank data/lang $dir ${dir}_ali ${dir}_denlats ${dir}_smbr
fi
###decode
dir=${dir}_smbr
acwt=0.03
if [ $stage -le 6 ]; then
        gmm=exp/tri4a
        dataset="TOCFL cyberon_chinese_test"
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
             steps/lmrescore_const_arpa.sh \
                 --cmd "$decode_cmd" data/lang_{3small,4large}_test \
                 ./data/$set/fbank $dir/decode_{3small,4large}_${set}
             endt=`date +%s`
             runtime=$((endt-startt))
             echo "rescoring time of 4large: $runtime"
        done
        for x in $dir/decode_*;
        do
                grep WER $x/wer_* | utils/best_wer.sh
        done
fi

