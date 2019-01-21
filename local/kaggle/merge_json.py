import os,sys,json
sys.path.append('local/data/')
from normalize_utils import *
from parse_choices import parse

def process_outputs(outputs):
    L = read_outputs(outputs)
    L2 = []
    for name,trans in L:
        if '-' in name:
            name,i=name.split('-')
            idx = int(name[1:].replace('.wav',''))
            trans = trans.replace(' ','')
            L2.append((idx,int(i),trans))
        else:
            idx = int(name[1:].replace('.wav',''))
            trans = trans.replace(' ','')
            L2.append((idx,1,trans))
    L2 =sorted(L2, key=lambda s: s[0])
    return L2
def write_d(key,X_list,L,n_best_idx = 1):
    for idx,n_best_i,value in X_list:
        if n_best_i == n_best_idx:
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
    n_best = sys.argv[5]
    result_json = sys.argv[6]
    
    n_best=int(n_best)

    A_list = process_outputs(A_outputs)
    if len(A_list) != 1500:
        print("len(A_list) = {}".format(len(A_list)))
    B_list = process_outputs(B_outputs)
    if len(B_list) != 1500:
        print("len(B_list) = {}".format(len(B_list)))
    C_list = process_outputs(C_outputs)
    if len(C_list) != 1500*n_best:
        print("len(C_list) = {}".format(len(C_list)))
    C_list_parse = []
    for idx,n_best_idx,trans in C_list:
        options = parse(trans)
        C_list_parse.append((idx,n_best_idx,options))
    
    all_idx = json.load(open(idx_json,'r'))
    all_idx = sorted(all_idx)
    
    for n_best_idx in range(1,n_best+1):
        L = []
        for idx in all_idx:
            d = {"context":"","question":"","options":["","","",""],"id":idx,"answer":-1}
            L.append(d)
        L = write_d("context",A_list,L,1)
        L = write_d("question",B_list,L,1)
        L = write_d("options",C_list_parse,L,n_best_idx)
        json.dump(L,open(result_json.replace('.json',str(n_best_idx)+'.json'),\
                         'w',encoding='utf8'),indent=4,ensure_ascii=False)



            
        
        
