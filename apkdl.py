#!/usr/bin/env python3

import sys
import requests
from dataclasses import dataclass
from bs4 import BeautifulSoup

BASE_URL = 'https://www.apkmirror.com'
HEADERS = {
    'User-Agent': 'banana'
}

@dataclass
class Apk:
    variant: str
    arch: str
    min_version: str
    screen_dpi: str
    download_page_url: str

def get_html(url):
    return BeautifulSoup(requests.get(url, headers=HEADERS).text, 'lxml')

def find_apk_page(app_id, version, arch=None):
    arch_string = f'&arch[]={arch}' if arch else ''
    search_page_url = f'{BASE_URL}/?post_type=app_release&searchtype=apk&s={app_id}-{version}{arch_string}&bundles[]=apk_files'
    return BASE_URL + get_html(search_page_url).select_one('.appRowTitle').a['href']

def parse_apk_variants(soup):
    table = soup.select_one('.variants-table')
    rows = table.select('.table-row')[1:]

    apks = []
    for row in rows:
        cells = row.select('.table-cell')
        apk = Apk(
            download_page_url = BASE_URL + cells[0].a['href'],
            variant = cells[0].select_one('.apkm-badge').text,
            arch = cells[1].text,
            min_version = cells[2].text,
            screen_dpi = cells[3].text,
        )
        apks.append(apk)

    return apks

def download_file(url, filename):
    with requests.get(url, headers=HEADERS, stream=True) as r:
        r.raise_for_status()
        with open(filename, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)


app_id = sys.argv[1]
version = sys.argv[2]
arch = sys.argv[3]
filename = sys.argv[4]

apk_page_url = find_apk_page(app_id, version, arch)
apks = parse_apk_variants(get_html(apk_page_url))
target_apks = [apk for apk in apks if apk.variant == 'APK' and apk.arch in [arch, 'universal']]
target_apks.sort(key = lambda arch: 1 if arch == 'universal' else 0)
download_button_url = BASE_URL + get_html(target_apks[0].download_page_url).select_one('.downloadButton')['href']
apk_download_url = BASE_URL + get_html(download_button_url).select_one('.notes a')['href']

download_file(apk_download_url, filename)
