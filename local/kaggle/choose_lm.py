import sys,os
sys.path.append('local/data/')
from normalize_utils import *

text_file = sys.argv[1]
output_dir = sys.argv[2]
with open(text_file,'r',encoding='utf-8') as f:
    for line in f:
        start = line.find(' ')
        token1 = line.split()[0]
        tex = normalize(line[start:].replace(' ',''))
        with open(os.path.join(output_dir,token1),'w',encoding='utf-8') as f:
            f.write(tex)
        

