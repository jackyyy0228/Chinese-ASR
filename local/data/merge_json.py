import os,sys,json
from normalize_utils import *
from parse_choices import parse

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
    A_outputs = sys.argv[1]
    B_outputs = sys.argv[2]
    C_outputs = sys.argv[3]
    idx_json = sys.argv[4]
    result_json = sys.argv[5]
    A_list = process_outputs(A_outputs)
    if len(A_list) != 1500:
        print("len(A_list) = {}".format(len(A_list)))
    B_list = process_outputs(B_outputs)
    if len(B_list) != 1500:
        print("len(B_list) = {}".format(len(B_list)))
    C_list = process_outputs(C_outputs)
    if len(C_list) != 1500:
        print("len(C_list) = {}".format(len(C_list)))
    all_idx = json.load(open(idx_json,'r'))
    all_idx = sorted(all_idx)
    L = []
    for idx in all_idx:
        d = {"context":"","question":"","options":["","","",""],"id":idx,"answer":-1}
        L.append(d)
    C_list_parse = []
    for idx,trans in C_list:
        options = parse(trans)
        C_list_parse.append((idx,options))
    L = write_d("context",A_list,L)
    L = write_d("question",B_list,L)
    L = write_d("options",C_list_parse,L)
    json.dump(L,open(result_json,'w',encoding='utf8'),indent=4,ensure_ascii=False)



        
    
    
