import numpy as np
import sys
best_lambda_file = sys.argv[1]
L = []
with open(best_lambda_file,'r',encoding='utf-8') as f:
    for line in f:
        L.append(float(line.rstrip()))
print(np.mean(L),np.var(L))

