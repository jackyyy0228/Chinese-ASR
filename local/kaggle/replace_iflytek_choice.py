import os,sys,json
from parse_choices import *
from normalize_utils import *



if __name__ == '__main__':
    choices_file =  sys.argv[1]
    iflytek_json = sys.argv[2]
    output_json = sys.argv[3]
    d = {}
    kaggle_dir = '/data/local/kgb/corpus/kgb/kaggle3'

    xlxs_path = os.path.join(kaggle_dir,'answer.xlsx') 
    content = read_xlsx(xlxs_path)
    '''
    with open(choices_file,'r',encoding='utf8') as f:
        for line in f:
            tokens = line.rstrip().split()
            text = ''.join(tokens[1:])
            name = tokens[0].replace('.wav','')
            No = int(name[1:])
            d[No] = parse(text)
    '''
    d2 = {}
    for idx,row in enumerate(content):
        if idx == 0:
            continue
        No,passage,question,c1,c2,c3,c4 = row[:7]
        No = int(No[1:])
        print(question)
        n_q = normalize(str(question),[])
        q = n_q.replace(' ','')
        d2[No] = q
    
        
    with open(iflytek_json,'r',encoding='utf8') as f:
        data = json.load(f)
    outputs = []
    for sample in data:
        id = sample['id']
        sample['options'] = d[id]
        sample['question'] = d2[id]
        outputs.append(sample)
    with open(output_json,'w',encoding='utf8') as f:
        json.dump(outputs,f,indent=4,ensure_ascii=False)

