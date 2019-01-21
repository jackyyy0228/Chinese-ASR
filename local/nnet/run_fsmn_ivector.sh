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
stage=4

if [ $stage -le 0 ]; then
  mkdir -p exp/nnet3/ivectors_train_sp_cyberon_chinese
  cat exp/nnet3/ivectors_train_sp/ivector_online.scp exp/nnet3/ivectors_cyberon_chinese_test/ivector_online.scp \
    > exp/nnet3/ivectors_train_sp_cyberon_chinese/ivector_online.scp
fi

##Make fbank features
if [ $stage -le 1 ]; then
    mkdir -p data/data_fbank
    fbankdir=data/fbank
    for x in train_sp cyberon_chinese_test TOCFL ; 
    do
      cp -r data/$x/mfcc40 data/$x/fbank
      steps/make_fbank.sh --nj 50 --cmd "$train_cmd"  --fbank-config conf/fbank.conf --name $x \
          data/$x/fbank exp/make_fbank/$x $fbankdir
      steps/compute_cmvn_stats.sh --name $x data/$x/fbank exp/make_fbank/$x $fbankdir
    done
fi
#####CE-training
lrate=0.00001
dir=exp/nnet/tri4a_${dnn_model}

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
        --learn_rate 0.000005  \
        --start_half_lr 5 --momentum 0.9 \
        --train-tool "nnet-train-fsmn-streams" \
        --feat-type plain --splice 1 \
        --cmvn-opts "--norm-means=true --norm-vars=false" --delta_opts "--delta-order=2" \
        --train-tool-opts "--minibatch-size=4096" \
        --ivector scp:exp/nnet3/ivectors_train_sp_cyberon_chinese/ivector_online.scp \
        --ivector-append-tool "append-ivector-to-feats --online-ivector-period=10" \
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
                 --ivector scp:exp/nnet3/ivectors_${set}/ivector_online.scp \
                 --ivector-append-tool "append-ivector-to-feats --online-ivector-period=10" \
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
exit 0
#gen ali & lat for smbr
nj=32
if [ $stage -le 5 ]; then
        steps/nnet/align.sh --nj $nj --cmd "$train_cmd" \
            --ivector scp:exp/nnet3/ivectors_train_sp_cyberon_chinese/ivector_online.scp \
            --ivector-append-tool "append-ivector-to-feats --online-ivector-period=10" \
            data/train_sp/fbank data/lang $dir ${dir}_ali
        steps/nnet/make_denlats.sh --nj $nj --cmd "$decode_cmd" --acwt $acwt \
            --ivector scp:exp/nnet3/ivectors_train_sp_cyberon_chinese/ivector_online.scp \
            --ivector-append-tool "append-ivector-to-feats --online-ivector-period=10" \
            data/train_sp/fbank data/lang $dir ${dir}_denlats
fi

####do smbr
if [ $stage -le 5 ]; then
        steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 2 --learn-rate 0.0000002 --acwt $acwt --do-smbr true \
            --ivector scp:exp/nnet3_cleaned/ivectors_train_960_dev_hires/ivector_online.scp \
            --ivector-append-tool "append-ivector-to-feats --online-ivector-period=10" \
            $data_fbk/train_960_cleaned data/lang $dir ${dir}_ali ${dir}_denlats ${dir}_smbr
fi
###decode
dir=${dir}_smbr
acwt=0.03
if [ $stage -le 4  ]; then
        gmm=exp/tri4a
        dataset="TOCFL cyberon_chinese_test"
        for set in $dataset
        do
             startt=`date +%s`
             steps/nnet/decode.sh --nj 12 --cmd "$decode_cmd" \
                 --acwt $acwt \
                 --ivector scp:exp/nnet3/ivectors_${set}/ivector_online.scp \
                 --ivector-append-tool "append-ivector-to-feats --online-ivector-period=10" \
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
