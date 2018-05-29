import os,sys,json,re
sys.path.append('local/data/tool/jieba-zh_TW')
import jieba
from opencc import OpenCC
from number2chinese import *

def main(wiki_corpus):
    openCC = OpenCC('s2t')  
    for root, dirs, files in os.walk(wiki_corpus, topdown=False):
        for name in files:
            txt_path = os.path.join(root,name)
            print(txt_path)
            with open(txt_path,'r',encoding='utf-8') as f:
                for line in f:
                    d = json.loads(line)
                    text = d['text'].replace('\n\n','\n')
                    text = openCC.convert(text)
                    text = text.upper()
                    tokens = jieba.cut(text)
                    new_tokens = []
                    for token in tokens:
                        if re.match('^[0-9]+$',token):
                            if len(token) > 15:
                                continue
                            token = to_chinese(int(token))
                        new_tokens.append(token)
                    text = ' '.join(new_tokens)
                    if len(text) > 0:
                        print(text)


if __name__ == '__main__':
    wiki_corpus = sys.argv[1]
    main(wiki_corpus)

