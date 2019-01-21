import sys,os
sys.path.append('local/kaggle')
sys.path.append('local/data/')
import xlsx
from normalize_utils import *
import itertools

if __name__ == '__main__':
    word_list = get_word_list('data/wfst/lang/words.txt')
    for i in range(4,5):
        xlsx_path = '/data/local/kgb/corpus/kgb/kaggle{}/answer.xlsx'.format(i)
        tmp = xlsx.get_content(xlsx_path,True,word_list)
        for row in tmp:
            for perm in list(itertools.permutations(row[3])):
                text = xlsx.merge_choice(perm,True)
                print(text)
            split_text = []
            for x in row[3]:
                split_text.append(' '.join(list(x.replace(' ',''))))
            for perm in list(itertools.permutations(split_text)):
                text = xlsx.merge_choice(perm,True)
                print(text)
                
    

