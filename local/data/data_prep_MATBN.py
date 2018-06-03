import sys,os,re
utf8_list = ['PTSNE20020813','PTSNE20020821','PTSNE20020816']
bad_token = ['@', '!', ';', '、', '\u3000', '|', '．', "'", '`', '?', ' ', ',', '1', '「', '-', '…', '：', '.', '}', '？', '。', '，', '；', '５', ':', '」', '１', '！', '『', '６', '2']


def read_sync_time(text):
    start = text.find("\"")
    end = text[start+1:].find("\"")
    time = text[start+1:start+end+1]
    return float(time)
def read_spk(text):
    start = text.find("\"")
    end = text[start+1:].find("\"")
    spk = text[start+1:start+end+1]
    spk = spk.replace('spk','').replace(' ','')
    if len(spk) == 0:
        spk = 0
    spk = convert_to_x_digits(spk,4)
    return spk
def convert_to_x_digits(integer,X):
    x = str(integer)
    y = x
    for i in range(X-len(x)):
        y = '0' + y
    return y
def get_segments_from_xml(file_name):
    trans = []
    s_time = []
    e_time = []
    spks = []
    with open(file_name,'r',encoding='utf-8') as f:
        prev_is_time = True
        now_trans = ''
        now_time = 0
        now_spk = '0000'
        for line in f:
            line = line.strip()
            if line.startswith('<Sync time'):
                time = read_sync_time(line)
                if not prev_is_time:
                    for token in bad_token:
                        now_trans = now_trans.replace(token,'')
                    now_trans = now_trans.replace('一','一').upper()

                    if len(now_trans) > 0:
                        trans.append(now_trans)
                        s_time.append(now_time)
                        e_time.append(time)
                        spks.append(now_spk)
                now_time = time
                now_trans = ''
                prev_is_time = True
            elif line.startswith('<Turn speaker'):
                spk = read_spk(line)
                now_spk = spk
            elif not line.startswith('<') and len(line) > 0:
                now_trans = now_trans + line
                prev_is_time = False
    return trans,s_time,e_time,spks
def main(corpus_path,file_type):
    for root, dirs, files in os.walk(corpus_path, topdown=False):
        for name in files:
            if name.endswith('.WAV'):
                wav_label = name.split('.')[0]
                wav_path = os.path.join(root,name)
                wav_path = os.path.abspath(wav_path)
                if file_type == 'wav.scp':
                    print(wav_label, wav_path)
                    continue

                trs_path = wav_path.replace('WAV','trs')
                if wav_label in utf8_list:
                    os.system('cp {} /tmp/temp'.format(trs_path))
                else:
                    os.system('iconv -f big5 -t utf8 {} > /tmp/temp'.format(trs_path))
                all_trans,s_time,e_time,spks = get_segments_from_xml('/tmp/temp')
                
                for trans,s,e,spk in zip(all_trans,s_time,e_time,spks):
                    strs = convert_to_x_digits(int(1000*s),8)
                    stre = convert_to_x_digits(int(1000*e),8)
                    seg_label = '_'.join([wav_label,spk,strs,stre])
                    if file_type == 'utt2spk':
                        print(seg_label, '_'.join([wav_label,spk]))
                    elif file_type == 'text':
                        sys.path.append('local/data/tool/jieba-zh_TW')
                        import jieba
                        trans = ' '.join(jieba.cut(trans))
                        trans = trans.upper()
                        print(seg_label, trans)
                    elif file_type == 'segments':
                        print(seg_label, wav_label, s, e)
    if file_type != 'wav.scp':
        os.remove('/tmp/temp')
                

if __name__ == '__main__':
    corpus_path = sys.argv[1]
    file_type = sys.argv[2]
    main(corpus_path,file_type)
            
        

