# -*- coding: utf-8 -*-  
from openpyxl import load_workbook
import re,os,sys,json
sys.path.append('local/data/')
from normalize_utils import *

def read_xlsx(file_name):
    wb = load_workbook(file_name)
    ws = wb.active
     
    rows = ws.rows
    columns = ws.columns
     
    content = []
    for idx,row in enumerate(rows):
        line = [col.value for col in row] 
        content.append(line)
    
    return content
def merge_choice(choices):
    c = ''
    chin = ['一','二','三','四']
    for idx,choice in enumerate(choices):
        c += chin[idx] + ' ' + choice + ' '
    return c
if __name__ == '__main__':
    result = sys.argv[1]
    kaggle_dir = '/data/local/kgb/corpus/kgb/kaggle3'
    
    xlxs_path = os.path.join(kaggle_dir,'answer.xlsx') 
    content = read_xlsx(xlxs_path)
    '''
    ## get all delete_symbols
    texts = ''
    for row in content:
        for idx in [1,2]:
            texts += row[idx]
    texts = strQ2B(texts)
    not_chinese = check_not_chinese(texts)
    print(set(not_chinese) - set(delete_symbols))
    '''
    data = json.load(open(result,'r',encoding='utf8'))
    d = {}
    for sample in data:
        id = sample['id']
        choices = sample['options']
        d[int(id)] = choices
    total =0 
    em = 0
    for idx,row in enumerate(content):
        if idx == 0:
            continue
        No,passage,question,c1,c2,c3,c4 = row[:7]
        No = int(No[1:])
        word_list = []
        c1 = normalize(str(c1),word_list)
        c2 = normalize(str(c2),word_list)
        c3 = normalize(str(c3),word_list)
        c4 = normalize(str(c4),word_list)
        c = [c1,c2,c3,c4]
        for x,y in zip(c,d[int(No)]):
            x = x.replace(' ','')
            y = y.replace(' ','')
            if x == y :
                em += 1
            total += 1
    print(em/total)
    
    
