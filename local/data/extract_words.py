import os,sys,re,string
from collections import Counter
from number2chinese import *

not_in_word=[ '`', '÷', '×', '≠', '<', '>', '|', '°', '┬', '┐', '├', '┼', '┤', '└', '┴', '│', '¯', '-', ';', '!', '¿', '·', '‘', '’', '"', '(', ')', '[', ']', '{', '}', '§', '®', '™', '@', '$', '€', '*', '&', '&&', '&&&', '±', '━', '←', '→', '↑', '↓', '♪', '╱', '╲', '◢', '◣', 'ˋ', '▁', '\x1b', '\x7f', '\x80', '¼', '½', '-', 'Á', 'À', 'Â', 'Å', 'Ä', 'Ā','（ ','˙','!', '(', ')', '-', '.', ':', '<', '>', '·', 'β', '—', '•', '℃', '。', '《', '》', 'ㄅ', 'ㄆ', 'ㄇ', 'ㄈ', 'ㄔ', 'ㄙ', 'ㄞ', 'ㄟ', '一', '\ue015', '\ue028', '\ufeff', '．', '：', 'Ｃ', 'Ｄ', 'Ｅ', 'Ｉ', 'Ｋ', 'Ｔ']


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
    train_path = sys.argv[3] #words must be in dictionary

    voc_size = int(voc_size)

    all_words = []
    c = Counter()
    with open(text_path, 'r', encoding='utf-8') as f:
        for line in f:
            tokens = line.rstrip().split()
            for token in tokens:
                if check_word(token):
                    continue
                token = token.upper()
                if re.match('^[0-9]+$',token):
                    if len(token) > 15:
                        continue
                    token = to_chinese(int(token))
                ch_word_list = re.findall(u'[\u4e00-\u9fff]+', token)
                if len(ch_word_list) == 0:
                    continue
                ch_word = ''.join(ch_word_list) #covert to word from list
                c.update([ch_word])
                all_words.append(ch_word)
                if len(ch_word) > 0 :
                    c.update(ch_word_list)
    vocabs = set([ x[0] for x in c.most_common(voc_size)])
    del c
    ## Add unknown character of train_corpus_words
    with open(train_path, 'r', encoding='utf-8') as f:
        for line in f:
            for token in line.rstrip().split():
                if token not in vocabs:
                    for character in list(token):
                        vocabs.add(character)
    for word in vocabs:
        print(word)
    


