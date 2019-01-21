import os,sys
from normalize_utils import *

def read_xlsx(file_name):
    wb = load_workbook(file_name)
    ws = wb.active # 获取特定的 worksheet
     
    rows = ws.rows
    columns = ws.columns
     
    # 行迭代
    content = []
    for idx,row in enumerate(rows):
        line = [col.value for col in row] # ['No', '文章', '問題', '選項1', '選項2', '選項3', '選項4', '正確答案']
        content.append(line)
    
    return content
def read_kaggle(file_name):
    content = read_xlsx(file_name)
    L = []
    word_list = get_word_list('data/lang/words.txt')
    for idx,row in enumerate(content):
        if idx == 0:
            continue
        No,passage,question,c1,c2,c3,c4 = row[:7]
        p = normalize(passage,word_list)
        q = normalize(question,word_list)
        c1 = normalize(str(c1),word_list)
        c2 = normalize(str(c2),word_list)
        c3 = normalize(str(c3),word_list)
        c4 = normalize(str(c4),word_list)
        c = merge_choice([c1,c2,c3,c4])
        L.append((No,p,q,c))
    return L
def merge_choice(choices):
    c = ''
    chin = ['一','二','三','四']
    for idx,choice in enumerate(choices):
        c += chin[idx] + ' ' + choice + ' '
    return c
def write(L,src_dir,kaggle_id):
    kaggle_id = str(kaggle_id)
    p_path = os.path.join(src_dir,'kaggle'+kaggle_id+'_A.txt')
    q_path = os.path.join(src_dir,'kaggle'+kaggle_id+'_B.txt')
    c_path = os.path.join(src_dir,'kaggle'+kaggle_id+'_C.txt')
    all_p = [x[1] for x in L]
    all_q = [x[2] for x in L]
    all_c = [x[3] for x in L]
    with open(p_path,'w',encoding='utf-8') as f:
        for p in all_p:
            f.write(p+'\n')
    with open(q_path,'w',encoding='utf-8') as f:
        for p in all_q:
            f.write(p+'\n')
    with open(c_path,'w',encoding='utf-8') as f:
        for p in all_c:
            f.write(p+'\n')
 
if __name__ == '__main__':
    src_dir='lm_test/text'
    L1 = read_kaggle("/data/local/kgb/corpus/kgb/kaggle1/answer.xlsx")
    L2 = read_kaggle("/data/local/kgb/corpus/kgb/kaggle2/answer.xlsx")
    L3 = read_kaggle("/data/local/kgb/corpus/kgb/kaggle3/answer.xlsx")
    write(L1,src_dir,1)
    write(L2,src_dir,2)
    write(L3,src_dir,3)
