import os,sys,json,re
sys.path.append('local/data/tool/jieba-zh_TW')
import jieba
from number2chinese import *

ptt_corpus = sys.argv[1]
crawl_path = os.path.join(ptt_corpus,'ptt_crawl.json')
ptt = json.load(open(crawl_path,'r'))
for item in ptt:
    text = item['Content']
    text = text.replace('\n\n','\n').replace(' ','')
    tokens = jieba.cut(text)
    new_tokens = []
    for token in tokens:
        if re.match('^[0-9]+$',token):
            if len(token) > 15:
                continue
            token = to_chinese(int(token))
        new_tokens.append(token)
    text = ' '.join(new_tokens)
    text = text.upper()
    if len(text) > 0:
        print(text)

