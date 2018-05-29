#!/usr/bin/python
#-*- encoding: utf-8 -*-

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

def to_chinese2(num):
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
def to_chinese(num):
    return to_chinese2(num).rstrip('零').replace('零零零', '零').replace('零零', '零')

if __name__ == '__main__':
    print(to_chinese(int(sys.argv[1])))
