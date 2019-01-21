import os,sys
sys.path.append('local/data/')
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
if __name__ == '__main__':
    test_dir='lambda_test'
    #L1 = read_kaggle("/data/local/kgb/corpus/kgb/kaggle1/answer.xlsx")
    #L2 = read_kaggle("/data/local/kgb/corpus/kgb/kaggle2/answer.xlsx")
    L = read_kaggle("/data/local/kgb/corpus/kgb/kaggle3/answer.xlsx")
    for idx,pair in enumerate(L) :
        No,p,q,c = pair
        srcdir=os.path.join(test_dir,str(idx))
        os.makedirs(srcdir)
        p_path = os.path.join(srcdir,'A.txt')
        c_path = os.path.join(srcdir,'C.txt')
        with open(p_path,'w',encoding='utf-8') as f:
            print(p)
            f.write(p)
        with open(c_path,'w',encoding='utf-8') as f:
            f.write(c)
