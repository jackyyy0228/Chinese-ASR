import sys
log_file = sys.argv[1]
s = open(log_file,encoding='utf8').read()
start = s.find('best lambda')
start = start + 13
end = s[start:].find(' ')
end+=start
end2 = s[end+1:].find(' ')
print(s[end+1:][:end2])
