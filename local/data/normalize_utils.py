#encoding=utf-8
from number2chinese import *
from openpyxl import load_workbook
#from delete_symbol import delete_symbols
delete_symbols = ['》', "'",'х', '★', '$', '…', 'р', '–', 'ế', '・', '[', '“', '‧', '﹪', ':', 'Ц', '%', 'Έ', 'м', '、', 'ς', '⋯', 'ㄧ', ';',',', 'н', '.', '♦', 'á', '~', '-', '〉', 'й', '㏄', ')', 'я', 'а','◎', '」', '—', 'о', '。', '』', '】', 'ж', 'ˋ', 'л', 'и', '【', ' ', 'В', '(', '°', '「', '♠', '!', ']', '+', '─', 'ω', 'ρ', '『', 'в', '○', 'т','&', '《', '•',  '∼', '#','♣', '”', '*', 'í', '\xa0', '?', 'е', '·', 'é', 'Т', '/', '〈', '℃', '>', 'Д', '♥', '\n', '"','；', '□', '’', '‘', '？', '！', '，', '：', '\u3000', '（', '）','〕', '－', '〔', 'ㄠ', 'ㄚ','￥', '＋', '．', '{']

symbols2= ['ꀀ', '䏞', '𡚒', '﹑', '䐡', '¨', '\t', '流', 'ˊ', '䒤', '﹖', '∶', '䆀', '䈴', 'ㄒ', '﹔', '﹐','ㄅ', '䍓', '䎴', '\u200b', '=', '䎃', '䍺', '၊', '¬', '𩃭', '䒴', 'Ṱ', '_', '䋊', '징', '\u0df0', 'ㄢ', '䇠', '䐚', 'ㄟ']
symbols3= ['ꀀ', '䏞', '𡚒', '﹑', '䐡', '¨', '\t', '流', 'ˊ', '䒤', '﹖', '∶', '䆀', 'ㄒ', '﹔', '﹐', '䰖', '狀', '類', 'ㄅ', '䍓', '䎴', '\u200b', '=', ' 䎃', '䍺', '၊', '¬', '𩃭', '䒴', 'Ṱ', '_', '䋊', '징', '\u0df0', 'ㄢ', '䇠', '䐚', 'ㄟ',"'ෟ'"]
symbols4=['\\', '¡', '¼', '\x80', '£', 'å', '»', '\x9c', '\x1b', '\x81', 'ç', 'ï', 'æ', '\x9d', '\xad','︺','︹','','','','',']']
delete_symbols += symbols2
delete_symbols += symbols3
delete_symbols += symbols4
with open('./local/data/delete_symbols','r',encoding='utf-8') as f:
    for line in f:
        delete_symbols.append(line.rstrip())
def check_not_chinese(text):
    not_chinese = []
    for cha in text:
        if len(re.findall(u'[\u4e00-\u9fa5]+', cha)) == 0 :
            if not re.match('[0-9a-zA-Z]',cha):
                not_chinese.append(cha)
    return set(not_chinese)
def strQ2B(ustring):
    rstring = ""
    for uchar in ustring:
        inside_code = ord(uchar)
        if inside_code == 12288: # 全形空格直接轉換
            inside_code = 32
        elif (inside_code >= 65281 and inside_code <= 65374): # 全形字元（除空格）根據關係轉化
            inside_code -= 65248
        rstring += chr(inside_code)
    return rstring
def remove_delete_symbols(texts):
    new_texts = ''
    S = set(delete_symbols)
    for cha in texts:
        if cha not in S:
            new_texts += cha
    return new_texts
def remove_punctuation(texts):
    all_puncs = re.findall('\([^\(^\)]*\)',texts)
    #print(all_puncs)
    for punc in all_puncs:
        if re.search('[a-zA-Z]',punc):
            texts = texts.replace(punc,'')
    return texts
def get_word_list(file_name):
    word_list = []
    with open(file_name,'r',encoding='utf-8') as f:
        for line in f:
            word_list.append(line.split()[0])
    return word_list
def split_word(text,word_list = None):
    if word_list is None:
        word_list = get_word_list('data/wfst/lang/words.txt')
    import jieba
    trans = ' '.join(jieba.cut(text))
    trans = trans.upper()
    new_trans = ''
    S = set(word_list)
    for word in trans.split():
        if re.search('[A-Z]',word):
            new_trans += word + ' '
            continue
        if word not in S:
            new_trans += ' '.join(list(word))
        else:
            new_trans += word
        new_trans += ' '
    return new_trans
def normalize(texts,word_list = None):
    texts = strQ2B(texts)
    texts = texts.replace('\n',' ')
    texts = remove_punctuation(texts)
    texts = remove_delete_symbols(texts)
    texts = replace_numbers(texts)
    texts = split_word(texts,word_list)
    return texts
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
def read_outputs(file_name):
    outputs = []
    with open(file_name,'r',encoding='utf-8') as f:
        for line in f:
            tokens = line.rstrip().replace('<UNK>','').split()
            name = tokens[0]
            trans = ' '.join(tokens[1:])
            outputs.append((name,trans))
    return outputs


