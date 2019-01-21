import sys,os
import argparse
def read_choose_lm(choose_lm):
    d = {}
    with open(choose_lm,'r') as f:
        for line in f:
            tokens = line.rstrip().split()
            idx = int(tokens[0][1:].replace('.wav',''))
            novel = tokens[1]
            d[idx] = novel
    return d
def process_A(src_dir,dirname,d = None):
    idx = int(dirname[1:])
    if d is None:
        lm = "data/LM/ori_A"
    elif idx not in d:
        lm = "data/LM/ori_A"
    else:
        lm = "data/LM/"+ d[idx] + "_A"
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)

def process_B(src_dir,dirname,d = None):
    idx = int(dirname[1:])
    if d is None :
        lm = "data/LM/ori_B"
    elif idx not in d:
        lm = "data/LM/ori_B"
    else:
        lm = "data/LM/"+ d[idx] + "_B"
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)
def process_C(src_dir,dirname,d = None):
    idx = int(dirname[1:])
    '''
    if d is None:
        lm = "data/LM/ori_C"
    elif idx not in d:
        lm = "data/LM/ori_C"
    else:
        lm = "data/LM/"+ d[idx] + "_C"
    '''
    if d is None:
        lm = "data/LM/ori_C"
    elif idx not in d:
        lm = "data/LM/ori_C"
    else:
        lm = "data/LM/"+ d[idx] + "_C_pruned"
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)
def process_C2(src_dir,dirname,C_lang_dir):
    idx = int(dirname[1:])
    lm = os.path.join(C_lang_dir,dirname,'rescore')
    if lm is not None:
        rescore_lang = os.path.join(src_dir,dirname,'rescore_lang')
        with open(rescore_lang,'w') as f:
            f.write(lm)
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--C_lang_dir',type=str,default="X")
    parser.add_argument('--choose_lm',type=str,default="X")
    parser.add_argument('--src_dir',type=str)
    args = parser.parse_args()

    src_dir = args.src_dir
    d = None
    if args.choose_lm != "X":
        d = read_choose_lm(args.choose_lm)
    for dirname in os.listdir(src_dir):

        if not os.path.isdir(os.path.join(src_dir,dirname)):
            continue
        idx = int(dirname[1:])
        typ = dirname[0]
        if 500 <= idx and  idx <= 1000:
            mode = os.path.join(src_dir,dirname,'mode')
            with open(mode,'w') as f:
                f.write('5')
        if idx % 2 == 0:
            use_gpu = os.path.join(src_dir,dirname,'use_gpu')
            with open(use_gpu,'w') as f:
                f.write('yes')
            
        if typ == 'A':
            process_A(src_dir,dirname,d)
        elif typ == 'B':
            process_B(src_dir,dirname,d)
        elif typ == 'C':
            if args.C_lang_dir == 'X':
                process_C(src_dir,dirname,d)
            else:
                process_C2(src_dir,dirname,args.C_lang_dir)
            
