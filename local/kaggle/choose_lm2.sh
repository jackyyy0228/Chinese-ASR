#!/bin/bash
. path.sh
iflytek_A_text=$1
test_dir=$2
output=$3
mkdir -p $test_dir
export LC_ALL='en_US.utf8'
for lm in ori news 20years nie guan laotsan water journey_west red_mansion 3kingdom beauty_n hunghuang lai_ho old_time one_gan lu_shun ; do
  (
    cat $iflytek_A_text | PYTHOIOENCODING="utf-8" python3 -c "
import sys
sys.path.append('local/data/')
from normalize_utils import *
for line in sys.stdin.readlines():
    start = line.find(' ')
    token1 = line.split()[0]
    tex = normalize(line[start:].replace(' ',''))
    print(tex)
"  | ngram -lm data/LM/$lm\_A.lm -ppl - -debug 1 | PYTHOIOENCODING=utf-8 python3 -c "
import sys
for line in sys.stdin.readlines():
  if 'zeroprobs' in line:
    start = line.find('ppl=')
    endd = line.find('ppl1=')
    print(line[start+5:endd])
  if line.startswith('file'):
    break
" > $test_dir/$lm
  ) & 
done
wait
PYTHOIOENCODING="utf-8" python3 local/kaggle/choose_lm2.py $iflytek_A_text $test_dir > $output


echo "Done choose_lm.sh."



