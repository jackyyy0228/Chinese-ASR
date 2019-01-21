#!/bin/bash
. path.sh
thread_num=56
iflytek_A_text=$1
test_dir=$2
output=$3
mkdir -p $test_dir

export output=$output


choose_lm(){
  tex=$1
  if [ -f $tex\_result ] ; then
    rm $tex\_result
  fi
  for lm in ori news 20years nie guan laotsan water journey_west red_mansion 3kingdom beauty_n hunghuang lai_ho old_time one_gan lu_shun ; do
    echo $lm >> $tex\_result
    cat $tex | ngram -lm lm_test/LM/$lm\_A.lm -ppl - | python3 local/kaggle/get_ppl.py - >> $tex\_result
  done
  wav=`basename $tex`
  python3 local/kaggle/max_ppl.py $wav $tex\_result 3 >> $output
}

export -f choose_lm

PYTHOIOENCODING=utf-8 python3 local/kaggle/choose_lm.py $iflytek_A_text $test_dir

parallel -j $thread_num "choose_lm {}" ::: $test_dir/*.wav

echo "Done choose_lm.sh."



