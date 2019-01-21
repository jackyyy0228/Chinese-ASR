import os,sys,json
sys.path.append('local/data/')
from parse_choices import *
from normalize_utils import *

def process_outputs(outputs):
    L = read_outputs(outputs)
    L2 = []
    for name,trans in L:
        idx = int(name[1:].replace('.wav',''))
        trans = trans.replace(' ','')
        L2.append((idx,trans))
    L2 =sorted(L2, key=lambda s: s[0])
    return L2
def write_d(key,X_list,L):
    for idx,value in X_list:
        for i,l in enumerate(L):
            if l["id"] == idx:
                L[i][key] = value
                break
    return L


if __name__ == '__main__':
    C_outputs =  sys.argv[1]
    iflytek_json = sys.argv[2]
    output_json = sys.argv[3]
    d = {}
    
    C_list = process_outputs(C_outputs)
    
    C_list_parse = []
    
    for idx,trans in C_list:
        options = parse(trans)
        C_list_parse.append((idx,options))
    
    with open(iflytek_json,'r',encoding='utf8') as f:
        L = json.load(f)
    
    L = write_d("options",C_list_parse,L)
    with open(output_json,'w',encoding='utf8') as f:
        json.dump(L,f,indent=4,ensure_ascii=False)

