import sys,os
from shutil import copyfile
null='開口，師兄，呆子嚇了一跳，起身了，初出江湖人稱把師傅變成，功能不夠涼快，一點，受傷之事，拉進去了，是這樣的效果，你掙扎着下來，還去當你的王太子，標上行裏最高的一張，坐盆裏去，沒人說你有類說，優雅，你可千萬不要偷懶，又要做師傅，趁着假日到花果山來了，阿姐一名男童說，不行不行，前幾天在白骨嶺上，他打死白骨精，我只當玩耍。老和尚揍他，那找和尚當日軍，把它作爲通訊協定書趕走，他，不知怎樣按摩，那風尚版六座，給我來上幾下，還活得成呢，滿滿說，的，會跟你記仇，你見了他別說吃住都難，確實辛苦他了，他見到這種情景，令人氣憤，定會有那怪爭鬥，管叫哪個妖精救出師傅扎針，八戒只有橫下一條心來。'
def read_choose_lm(choose_lm):
    d = {}
    with open(choose_lm,'r') as f:
        for line in f:
            tokens = line.rstrip().split()
            idx = int(tokens[0][1:].replace('.wav',''))
            novel = null
            if len(tokens) > 1:
                novel = tokens[1]
            d[tokens[0]] = novel 
    return d
d = read_choose_lm(sys.argv[1])
wav_dir = sys.argv[2]
L = []
for wav in os.listdir(wav_dir):
    if wav.endswith('.wav'):
        if wav not in d:
            d[wav] = null
with open(sys.argv[3],'w') as f:
    for k,v in d.items():
        f.write('{} {} \n'.format(k,v))


