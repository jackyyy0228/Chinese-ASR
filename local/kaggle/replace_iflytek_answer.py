from xlsx import *
import sys,os


if __name__ == '__main__':
    iflytek_json = sys.argv[1]
    output_json = sys.argv[2]
    kaggle_id = sys.argv[3]
    d = {}
    ans_path = '/data/local/kgb/corpus/kgb/kaggle{}/answer.xlsx'.format(kaggle_id)
    L = get_content(ans_path,False)

    for (No,p,q,c,answer) in L:
        d[No] = answer 
    
    with open(iflytek_json,'r',encoding='utf8') as f:
        data = json.load(f)
    outputs = []
    for sample in data:
        id = sample['id']
        if id in d:
            sample['answer'] = d[id]
        outputs.append(sample)
    with open(output_json,'w',encoding='utf8') as f:
        json.dump(outputs,f,indent=4,ensure_ascii=False)

