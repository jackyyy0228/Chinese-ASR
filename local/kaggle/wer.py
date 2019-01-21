import json,sys
sys.path.append('local/data/')
import numpy
import argparse
from xlsx import *
from tqdm import tqdm
from parse_choices import parse

def editDistance(r, h):
    '''
    This function is to calculate the edit distance of reference sentence and the hypothesis sentence.
    Main algorithm used is dynamic programming.
    Attributes:
        r -> the list of words produced by splitting reference sentence.
        h -> the list of words produced by splitting hypothesis sentence.
    '''
    d = numpy.zeros((len(r)+1)*(len(h)+1), dtype=numpy.uint8).reshape((len(r)+1, len(h)+1))
    for i in range(len(r)+1):
        for j in range(len(h)+1):
            if i == 0:
                d[0][j] = j
            elif j == 0:
                d[i][0] = i
    for i in range(1, len(r)+1):
        for j in range(1, len(h)+1):
            if r[i-1] == h[j-1]:
                d[i][j] = d[i-1][j-1]
            else:
                substitute = d[i-1][j-1] + 1
                insert = d[i][j-1] + 1
                delete = d[i-1][j] + 1
                d[i][j] = min(substitute, insert, delete)
    return d

def wer(r, h):
    # build the matrix
    err = 0
    total_len = 0
    for r0,h0 in tqdm(zip(r,h)):
        r0 = r0.replace(' ','')
        h0 = h0.replace(' ','')
        d = editDistance(r0, h0)
        err += float(d[len(r0)][len(h0)])
        total_len += len(r0)
        #print(err/total_len)
    return err/total_len
def read_text(file_name):
    d = {}
    with open(file_name,'r',encoding='utf-8') as f:
        for line in f:
            tokens = line.rstrip().split()
            name = tokens[0]
            text = ' '.join(tokens[1:])
            d[name] = text.replace(' ','')
    return d 
def merge_choice(choices,special_symbols=False):
    c = ''
    if special_symbols:
        chin = ['<one>','<two>','<three>','<four>']
    else:
        chin = ['一','二','三','四']
    for idx,choice in enumerate(choices):
        c += chin[idx] + ' ' + choice + ' '
    return c
if __name__ == '__main__':
    
    
    xlxs_path = '/data/local/kgb/corpus/kgb/kaggle5/answer.xlsx'
    n_best = False
    print('n_best:',n_best)
    if n_best:
        n5_id = str(sys.argv[2])
    content = read_xlsx(xlxs_path)
    '''
    with open('iflytek/kaggle3.json', 'r',encoding='utf-8') as f:
        data = json.load(f)
    
    r = []
    h = []
    for sample in tqdm(data):
        id = sample['id']
        tex = sample['question']
        for row in content:
            if row[0] == 'No' or row[0] is None :
                continue
            if int(row[0][1:]) == int(id):
                r.append(normalize(row[2],[]))
                h.append(normalize(tex,[]))
                #print(row[1],tex)
    print(wer(r,h))
    '''
    r = []
    h = []
    d = read_text(os.path.join(sys.argv[1],'output.txt'))
    #d = read_text('0914/C_mode5_Clang/output.txt')
    #d = read_text('0914/C/output.txt')
    total = 0
    em = 0
    for name,text in d.items():
        name = name[1:].replace('.wav','')
        if n_best :
            if not name.endswith(n5_id):
                continue
            name = name.replace('-' + n5_id,'')
        id = int(name)
        for idx,row in enumerate(content):
            if idx==0:
                continue
            try:
                No,passage,question,c1,c2,c3,c4 = row[:7]
            except:
                continue
            if int(No) == int(id):
                c1 = normalize(str(c1),[])
                c2 = normalize(str(c2),[])
                c3 = normalize(str(c3),[])
                c4 = normalize(str(c4),[])
                c = merge_choice([c1,c2,c3,c4],False)
                text2 = text.replace('<one>','一').replace('<two>','二').replace('<three>','三').replace('<four>','四')
                r.append(normalize(c,[]))
                h.append(normalize(text2,[]))
                #print(text)
                choices = parse(text)
                #print(choices)
                for ci,cj in zip([c1,c2,c3,c4],choices):
                    ci = ci.replace(' ','')
                    cj = cj.replace(' ','')
                    if ci == cj:
                        em += 1
                    else:
                        print(ci,cj)
                    total += 1
    print(em/total)
    print(wer(r,h))
