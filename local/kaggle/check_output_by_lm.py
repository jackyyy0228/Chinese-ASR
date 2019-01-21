import os,sys
sys.path.append('local/data/')
from normalize_utils import *
src_dir=sys.argv[1]
write_output = True

def find_3small_trans(lm,wav):
    output_path = os.path.join(src_dir,lm,'decode_3small/output.txt')
    L_small = read_outputs(output_path)
    for l in L_small:
        if l[0] == wav:
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
                if wav not in L2:
                    missing.append(wav)
            if len(missing) > 0:
                print(d)
                wrong =True
                for m in missing:
                    print(m+'.wav')
                    small_all.append((str(m),find_3small_trans(d,m)))

if write_output :
    for x in small_all:
        print(x)
        L.append(x)
    L = sorted(L,key=lambda x:x[0])
    with open(os.path.join(src_dir,'output.txt'),'w',encoding='utf-8') as f:
        for x,y in L:
            f.write(x + ' ' + y + '\n')
else:
    if len(small_all) > 0:
        for x in small_all:
            print(x)


            
if not wrong:
    print("All wav files have outputs.")
    



