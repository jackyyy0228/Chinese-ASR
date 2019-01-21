import os,sys,re
import types,sys

class NotIntegerError(Exception):
    pass

class OutOfRangeError(Exception):
    pass

_MAPPING = (u'零', u'一', u'二', u'三', u'四', u'五', u'六', u'七', u'八', u'九', )
_P0 = (u'', u'十', u'百', u'千', )
_S4, _S8, _S16 = 10 ** 4 , 10 ** 8, 10 ** 16
_MIN, _MAX = 0, 9999999999999999

def _to_chinese4(num):
    '''转换[0, 10000)之间的阿拉伯数字
    '''
    assert(0 <= num and num < _S4)
    if num < 10:
        return _MAPPING[num]
    else:
        lst = [ ]
    while num >= 10:
        lst.append(num % 10)
        num = num // 10
    lst.append(num)
    c = len(lst)  # 位数
    result = u''

    for idx, val in enumerate(lst):
        if val != 0:
            result += _P0[idx] + _MAPPING[val]
        if idx < c - 1 and lst[idx + 1] == 0:
            result += u'零'

    return result[::-1].replace(u'一十', u'十')

def _to_chinese8(num):
    assert(num < _S8)
    to4 = _to_chinese4
    if num < _S4:
        return to4(num)
    else:
        mod = _S4
    high, low = num // mod, num % mod
    if low == 0:
        return to4(high) + u'萬'
    else:
        if low < _S4 // 10:
            return to4(high) + u'萬零' + to4(low)
        else:
            return to4(high) + u'萬' + to4(low)

def _to_chinese16(num):
    assert(num < _S16)
    to8 = _to_chinese8
    mod = _S8
    high, low = num // mod, num % mod
    if low == 0:
        return to8(high) + u'億'
    else:
        if low < _S8 // 10:
            return to8(high) + u'億零' + to8(low)
        else:
            return to8(high) + u'億' + to8(low)

def to_chinese(num):
    if type(num) != type(int(100)):
        raise NotIntegerError(u'%s is not a integer.' % num)
    if num < _MIN or num > _MAX:
        raise OutOfRangeError(u'%d out of range[%d, %d)' % (num, _MIN, _MAX))

    if num < _S4:
        return _to_chinese4(num)
    elif num < _S8:
        return _to_chinese8(num)
    else:
        return _to_chinese16(num)
def num_to_chinese(num):
    return to_chinese(num).rstrip('零').replace('零零零', '零').replace('零零', '零')
def decimal_to_chinese(num):
    token = ''
    for char in str(num):
        token += _MAPPING[int(char)]
    return token
def float_to_chinese(_float):
    char = str(_float)
    num1,num2 = char.split('.')
    return num_to_chinese(int(num1)) + '點' + decimal_to_chinese(num2)
def fraction_to_chinese(frac):
    frac = str(frac)
    num1,num2 = frac.split('/')
    return num_to_chinese(int(num2)) + '分之' + num_to_chinese(int(num1))
def time_to_chinese(time):
    time = str(time)
    hour,mininute = time.split(':')
    hour_chi = num_to_chinese(int(hour))
    if hour == '2':
        hour_chi = '兩'
    mininute_chi = num_to_chinese(int(mininute))
    return hour_chi + '點' + mininute_chi + '分'
def year_to_chinese(year):
    if year == '2000年':
        return '兩千年'
    new = ''
    for cha in year:
        if re.search('[0-9]',cha):
            new += _MAPPING[int(cha)]
        else:
            new += cha
    return new
def replace_numbers(text):
    years = re.findall(r'\d*年',text)
    for token in years:
        char = year_to_chinese(token)
        text = text.replace(token,char)

    numbers = re.findall(r'-?\d+\.?/?:?\d*', text)
    numbers = sorted(numbers,key= lambda x : len(x), reverse = True)
    for token in numbers:
        if len(token) > 14:
            text = text.replace(token, '')
            continue
        char = ''
        if token[0] == '-':
            char = '負'
            token = token[1:]
        if '.' in token:
            char += float_to_chinese(float(token))
        elif '/' in token:
            char += fraction_to_chinese(str(token))
        elif ':' in token:
            char += time_to_chinese(str(token))
        else:
            char += num_to_chinese(int(token))
        text = text.replace(token, char)
    return text

if __name__ == '__main__':
    test = '我1900年2:30在3/2街'
    print(replace_numbers(test))
