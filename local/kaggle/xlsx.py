import os,sys,json
sys.path.append('local/data/')
from parse_choices import *
from normalize_utils import *

def read_xlsx(file_name):
    wb = load_workbook(file_name)
    ws = wb.active
     
    rows = ws.rows
    columns = ws.columns
     
    content = []
    for idx,row in enumerate(rows):
        line = []
        for idx,col in enumerate(row):
            if idx == 0 and col.value is None:
                break
            if col.value is not None:
                line.append(col.value)
            else:
                break
        content.append(line)
    return content
def merge_choice(choices,special_symbols=False):
    c = ''
    if special_symbols:
        chin = ['<one>','<two>','<three>','<four>']
    else:
        chin = ['一','二','三','四']
    for idx,choice in enumerate(choices):
        c += chin[idx] + ' ' + choice + ' '
    return c
def get_content(filename,is_normalize = True,word_list=[]):
    content = read_xlsx(filename)
    L = []
    for idx,row in enumerate(content):
        if idx == 0:
            continue
        try:
            No,p,q,c1,c2,c3,c4,answer = row[:8]
        except:
            continue
        No = int(str(No).replace('A',''))
        if is_normalize:
            c1 = normalize(str(c1),word_list)
            c2 = normalize(str(c2),word_list)
            c3 = normalize(str(c3),word_list)
            c4 = normalize(str(c4),word_list)
            p = normalize(p)
            q = normalize(q)
        c = [c1,c2,c3,c4]
        answer = int(str(answer).replace('選項',''))
        L.append((No,p,q,c,answer))
    return L
def kaggle_to_json(xlsx_path,result_json_path):
    L = get_content(xlsx)
    L2 = []
    for (No,p,q,c,answer) in L:
        for idx in range(len(c)):
            c[idx] = c[idx].replace(' ','')
        d = {"context":p.replace(' ',''),"question":q.replace(' ',''),"options":c,"id":No,"answer":answer}
        L2.append(d)
    json.dump(L2,open(result,'w',encoding='utf8'),indent=4,ensure_ascii=False)

if __name__ == '__main__':
    result = sys.argv[1]
    xlsx = '/data/local/kgb/corpus/kgb/kaggle1/answer.xlsx'
    kaggle_to_json(xlsx,result)

