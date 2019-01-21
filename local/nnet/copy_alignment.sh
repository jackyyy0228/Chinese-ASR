#!/bin/bash
. path.sh
dir=$1
aug(){
  ali=$1
  gunzip -c $ali | copy-int-vector  ark:- ark,t:- | python3 -c " 
import sys
for line in sys.stdin.readlines():
  tokens = line.rstrip().split()
  label = tokens[0]
  values = ' '.join(tokens[1:])
  print(label + '-aug',values)
  print(label ,values)
  #print('rvb1_'+label,values)
  #print(label+'-aug_kgb_noise',values)
" | copy-int-vector  ark,t:- ark:- | gzip -c > $ali\_after
  mv $ali\_after $ali
  echo "Done $ali"
}

export -f aug

parallel -j 20 "aug {}" ::: $dir/ali.*.gz

wait

