# -*- coding: utf-8 -*-
import requests,sys
from bs4 import BeautifulSoup  

# https://www.ettoday.net/news/news-list-2017-07-15-5.htm
# 1 政治 
# 17 財經
# 2 國際
# 6 社會
# 9 影劇
# 10 體育
# 20 3c
# 30 時尚 
# 24 遊戲
# 5 生活
for tt in [1, 17, 2, 6, 9, 10, 20, 30, 24, 5]:
    urls = []
    for n in range(1,12):
        for n2 in [5,10,15,20,25,31]:
            u = "https://www.ettoday.net/news/news-list-"+str(sys.argv[1]) + "-" + str(n)+"-"+str(n2)+"-"+str(tt)+".htm"
            res = requests.get(u)
            soup = BeautifulSoup(res.content, "lxml")
            soup = soup.find("div", class_="part_list_2")
            domian = "https://www.ettoday.net"
            for a in soup.find_all("h3"):
                urls.append(domian+a.a['href'])
    allcontent = []
    for u in urls:
        content = []
        res = requests.get(u)
        soup = BeautifulSoup(res.content, "lxml")
        try:
            soup = soup.find("div", class_="story")
            for a in soup.find_all("p"):
                p = a.string
                if p != None:
                    p = p.split('/')
                    if len(p) > 1:
                        content.append(p[1])
                        print(p[1].encode('utf-8'))
                    else:
                        content.append(p[0])
                        print(p[0].encode('utf-8'))
            allcontent.append(content.encode('utf-8'))
        except:
            pass
    print(len(allcontent))
