from bs4 import BeautifulSoup
import requests
import re

HEADERS = {
    'User-Agent': 'banana'
}

versions = []
soup = BeautifulSoup(requests.get('https://www.apkmirror.com/apk/google-inc/youtube/', headers=HEADERS).text, 'lxml')
for node in soup.select('.appRowTitle'):
    match = re.fullmatch(r'YouTube ([0-9]+\.[0-9]+\.[0-9]+)', node['title'])
    if match:
        versions.append(match.group(1))

if not versions:
    exit(1)

print(versions[0])
