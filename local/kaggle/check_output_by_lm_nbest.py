import os,sys
sys.path.append('local/data/')
from normalize_utils import *
src_dir=sys.argv[1]
nbest = int(sys.argv[2])

def find_3small_trans(lm,wav):
    output_path = os.path.join(src_dir,lm,'decode_rescore/output.txt')
    output_path = os.path.join(src_dir,'../C/output.txt')
    L_rescore = read_outputs(output_path)
    idx = wav[-1]
    wav_i = wav[:-2]
    for l in L_rescore:
        if l[0] == wav_i:
            print(wav_i)
            return l[1]
    output_path = os.path.join(src_dir,lm,'decode_3small/output.txt')
    L_small = read_outputs(output_path)
    for l in L_small:
        if l[0] == wav_i:
            return l[1]
    return "None"

## read from output.txt 
output_path = os.path.join(src_dir,'output.txt')

L = read_outputs(output_path)
L2 = [x.replace('.wav','') for x,y in L]
missing_trans = []
wrong = False

for name,trans in L:
    f_name = name.replace('.wav','')
    if len(trans) == 0 :
        missing_trans.append(name)

if len(missing_trans) > 0:
    wrong = True
    for f in missing_trans:
        print(f)
    print("Missing {}  trans.".format(len(missing_trans)))

small_all = []

for d in os.listdir(src_dir):
    d_path = os.path.join(src_dir,d)
    if os.path.isdir(d_path):
        with open(os.path.join(d_path,'wav.scp'),'r') as f:
            missing = []
            for line in f:
                wav = line.split()[0]
                for i in range(1,nbest+1):
                    wav_i = wav + '-' + str(i)
                    if wav_i not in L2:
                        missing.append(wav_i)
            if len(missing) > 0:
                print(d)
                wrong =True
                for m in missing:
                    print(m+'.wav')
                    small_all.append(str(m) + ' ' + find_3small_trans(d,m) )
if len(small_all) > 0:
    for x in small_all:
        print(x)
if not wrong:
    print("All wav files have outputs.")
    



