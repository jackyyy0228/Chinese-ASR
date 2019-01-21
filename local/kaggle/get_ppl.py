import sys
S = sys.stdin.read()
start = S.find('ppl=')
endd = S.find('ppl1=')
print(S[start+5:endd])
