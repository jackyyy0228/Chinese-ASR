#!/usr/bin/env python
# encoding=utf-8
# Copyright 2018 AIShell-Foundation(Authors:Jiayu DU, Xingyu NA, Bengu WU, Hao ZHENG)
#           2018 Beijing Shell Shell Tech. Co. Ltd. (Author: Hui BU)
# Apache 2.0

import sys
from normalize_utils import *

if len(sys.argv) < 3:
  sys.stderr.write("word_segmentation.py <vocab> <trans> > <word-segmented-trans>\n")
  exit(1)

vocab_file=sys.argv[1]
trans_file=sys.argv[2]
word_list = get_word_list(vocab_file)

for line in open(trans_file,'r',encoding='utf-8'):
  key,trans = line.strip().split('\t',1)
  new_line = key + '\t' + normalize(trans,word_list)
  print(new_line)
