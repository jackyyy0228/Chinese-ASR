import sys
log_file = sys.argv[1]
s = open(log_file,encoding='utf8').read()
start = s.find('best lambda')
start = start + 13
end = s[start:].find(' ')
end+=start
print(s[start:end])
