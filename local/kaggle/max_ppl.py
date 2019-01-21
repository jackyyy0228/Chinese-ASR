import sys
import numpy as np
names = []
scores = []
wav_name = sys.argv[1]
flag=sys.argv[3]
with open(sys.argv[2],'r') as f:
    for idx,line in enumerate(f):
        if idx %2 == 0 :
            name = line.rstrip()
            names.append(name)
        else:
            score = line.rstrip()
            scores.append(float(score))
min_idx = np.argmin(scores)
min_name = names[min_idx]
min_score = scores[min_idx]
if flag == '3':
    print(wav_name,min_name,min_score)
else:
    print(min_name)

