#!/bin/bash
# Copyright 2018 AIShell-Foundation(Authors:Jiayu DU, Xingyu NA, Bengu WU, Hao ZHENG)
#           2018 Beijing Shell Shell Tech. Co. Ltd. (Author: Hui BU)
# Apache 2.0

# transform raw AISHELL-2 data to kaldi format

. ./path.sh || exit 1;

tmp=
dir=

. ./local/data/corpus_path.sh

corpus=$aishell2
tmp=data/tmp
dir=data/aishell2/mfcc39
words=data/wfst/lang/words.txt

echo "prepare_data.sh: Preparing data in $corpus"
echo $corpus
mkdir -p $tmp
mkdir -p $dir

# corpus check
if [ ! -d $corpus ] || [ ! -f $corpus/wav.scp ] || [ ! -f $corpus/trans.txt ]; then
  echo "Error: $0 requires wav.scp and trans.txt under $corpus directory."
  exit 1;
fi

#to traditional chinese
opencc -i $corpus/trans.txt -o $corpus/trans_tra.txt
#format trans.txt
cat $corpus/trans_tra.txt  | awk '{split($0,a,"/"); print a[2]}'  | awk '{split($0,a,".wav"); print a[1],a[2]}' > $tmp/trans_tra.txt
# validate utt-key list
awk '{print $1}' $corpus/wav.scp   > $tmp/wav_utt.list
awk '{print $1}' $tmp/trans_tra.txt  > $tmp/trans_utt.list
utils/filter_scp.pl -f 1 $tmp/wav_utt.list $tmp/trans_utt.list > $tmp/utt.list

# wav.scp
awk -F'\t' -v path_prefix=$corpus '{printf("%s\t%s/%s\n",$1,path_prefix,$2)}' $corpus/wav.scp > $tmp/tmp_wav.scp
utils/filter_scp.pl -f 1 $tmp/utt.list $tmp/tmp_wav.scp | sort -k 1 | uniq > $tmp/wav.scp

# text
python3 -c "import jieba" 2>/dev/null || \
  (echo "jieba is not found. Use tools/extra/install_jieba.sh to install it." && exit 1;)
utils/filter_scp.pl -f 1 $tmp/utt.list $tmp/trans_tra.txt | sort -k 1 | uniq > $tmp/trans.txt
awk '{print $1}' $words | sort | uniq | awk 'BEGIN{idx=0}{print $1,idx++}'> $tmp/vocab.txt
PYTHONIOENCODING=utf-8 python3 local/data/word_segmentation.py $tmp/vocab.txt $tmp/trans.txt > $tmp/text

# utt2spk & spk2utt
awk -F'\t' '{print $2}' $tmp/wav.scp > $tmp/wav.list
sed -e 's:\.wav::g' $tmp/wav.list | \
  awk -F'/' '{i=NF-1;printf("%s\t%s\n",$NF,$i)}' > $tmp/tmp_utt2spk
utils/filter_scp.pl -f 1 $tmp/utt.list $tmp/tmp_utt2spk | sort -k 1 | uniq > $tmp/utt2spk
utils/utt2spk_to_spk2utt.pl $tmp/utt2spk | sort -k 1 | uniq > $tmp/spk2utt

# copy prepared resources from tmp_dir to target dir
mkdir -p $dir
for f in wav.scp text spk2utt utt2spk; do
  cp $tmp/$f $dir/$f || exit 1;
done

utils/fix_data_dir.sh $dir || exit 1;

echo "local/prepare_data.sh succeeded"
exit 0;
