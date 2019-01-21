#encoding=utf-8
import sys
import numpy as np
sys.path.append('local/data/')
from normalize_utils import *

iflytek_A = sys.argv[1]
test_dir=sys.argv[2] 

L = []
with open(iflytek_A,'r') as f:
    for line in f:
        start = line.find(' ')
        token1 = line.split()[0]
        L.append(token1)
L2 = []
lms = []
for lm in os.listdir(test_dir):
    lms.append(lm)
    temp = []
    with open(os.path.join(test_dir,lm),'r') as f:
        for line in f:
            temp.append(float(line))
    L2.append(temp)
n_line,n_lm = len(L),len(L2)
scores = np.array(L2).transpose()
for i in range(n_line):
    max_score = np.min(scores[i])
    lm = lms[np.argmin(scores[i])]
    print(L[i],lm,max_score)
