import os
import sys
sys.path.append('local/data/')
from normalize_utils import *

def read_choose_lm(lm_file):
    d = {}
    with open(lm_file,'r') as f:
        for line in f:
            tokens = line.rstrip().split()
            name = tokens[0][1:].replace('.wav','')
            idx = int(name)
            novel = tokens[1]
            d[idx] = novel
    return d
def process_C(idx):
    lm = "lm_test/LM/"+ d[idx] + "_C.lm"
    return lm
if __name__ == '__main__':
    A_outputs = sys.argv[1]
    C_lang_dir = sys.argv[2]
    choose_lm = sys.argv[3]
    outputs = read_outputs(A_outputs)
    d = read_choose_lm(choose_lm)
    for (name,trans) in outputs:
        idx = int(name[1:].replace('.wav',''))
        name = name.replace('.wav','').replace('A','C')
        src_dir = os.path.join(C_lang_dir,name)
        os.makedirs(src_dir)

        A_txt_path = os.path.join(src_dir,'A.txt') 
        with open(A_txt_path,'w',encoding='utf-8') as f:
            f.write(trans)

        lm = process_C(idx)
        ori_lm = os.path.join(os.getcwd(),lm)
        lm_path = os.path.join(src_dir,'lm_path')
        with open(lm_path,'w') as f:
            f.write(lm)
        

