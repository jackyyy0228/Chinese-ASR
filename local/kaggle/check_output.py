import os,sys
sys.path.append('local/data/')
from normalize_utils import *
src_dir=sys.argv[1]
d_list = []
for d in os.listdir(src_dir):
    if os.path.isdir(os.path.join(src_dir,d)):
        d_list.append(d)
output_path = os.path.join(src_dir,'output.txt')

L = read_outputs(output_path)
missing_trans = []

for name,trans in L:
    f_name = name.replace('.wav','')
    if len(trans) == 0 :
        missing_trans.append(name)



missing_files =[]
L2 = [x.replace('.wav','') for x,y in L]
for d in d_list:
    if d not in L2:
        missing_files.append(d+'.wav')

wrong = False
if len(missing_files) > 0:
    wrong = True
    for f in missing_files:
        print(f)
    print("Missing {}  files.".format(len(missing_files)))
if len(missing_trans) > 0:
    wrong = True
    for f in missing_trans:
        print(f)
    print("Missing {}  trans.".format(len(missing_trans)))
if not wrong:
    print("All wav files have outputs.")
    


