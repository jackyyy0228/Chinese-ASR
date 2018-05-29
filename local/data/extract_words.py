import os,sys,re,string
from collections import Counter
from number2chinese import *

sys.path.append('local/data/tool/jieba-zh_TW')
import jieba
not_in_word=[ '`', '÷', '×', '≠', '<', '>', '|', '°', '┬', '┐', '├', '┼', '┤', '└', '┴', '│', '¯', '-', ';', '!', '¿', '·', '‘', '’', '"', '(', ')', '[', ']', '{', '}', '§', '®', '™', '@', '$', '€', '*', '&', '&&', '&&&', '±', '━', '←', '→', '↑', '↓', '♪', '╱', '╲', '◢', '◣', 'ˋ', '▁', '\x1b', '\x7f', '\x80', '¼', '½', '-', 'Á', 'À', 'Â', 'Å', 'Ä', 'Ā','（ ','˙']


def check_word(word):
    for item in ['#','.',' ','、','「','」','”','“','…','）','）','：','，',':','?','、','。','；','！','+','_']:
        if item in word:
            return False
    for item in not_in_word:    
        if item in word:
            return False
    for idx in range(10):
        item = str(idx)
        if item in word:
            return False
    return True

if __name__ == '__main__':
    voc_size = sys.argv[1]
    text_path = sys.argv[2]
    voc_size = int(voc_size)

    all_words = []
    with open(text_path, 'r', encoding='utf-8') as f:
        for line in f:
            tokens = line.rstrip().split()
            for token in tokens:
                token = token.upper()
                if re.match('^[0-9]+$',token):
                    if len(token) > 15:
                        continue
                    token = to_chinese(int(token))
                if check_word(token):
                    all_words.append(token)
                ch_word = re.findall(u'[\u4e00-\u9fff]+', token)
                if len(ch_word) > 0:
                    for cha in ch_word:
                        all_words.append(cha)
    c = Counter(all_words)
    vocabs = c.most_common(voc_size)
    for word in vocabs:
        print(word[0])
    


