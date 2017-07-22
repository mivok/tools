#!/usr/bin/env python3
# Web clipper using mercury and html2text
#
# To install dependencies: pip3 install requests html2text pyperclip
#
from __future__ import print_function

import os
import re
import sys

import requests
import html2text
import pyperclip

class WebClipper(object):

    def __init__(self):
        self.api_key_path=os.path.expanduser("~/.mercuryapikey")
        self.mercury_url="https://mercury.postlight.com/parser"
        self.api_key = self.load_api_key()

    def load_api_key(self):
        with open(self.api_key_path) as fh:
            return fh.read().strip()

    def readability(self, url):
        r = requests.get(self.mercury_url, params={"url": url},
                         headers={'x-api-key': self.api_key})
        if 'message' in r.json():
            print("Error running readability: %s" % r.json()['message'])
            sys.exit(1)
        return r.json()

    def tag_callback(self, tag, attrs, start):
        """This lets us override existing functionality in html2text"""
        if tag == 'li':
            # The only change from html2text here is the indentation of the list
            # (I want lists to start at column 1 and be 4 space indented)
            self.pbr()
            if start:
                if self.list:
                    li = self.list[-1]
                else:
                    li = {'name': 'ul', 'num': 0}
                if self.google_doc:
                    nest_count = self.google_nest_count(tag_style)
                else:
                    nest_count = len(self.list)
                self.o("    " * (nest_count - 1))
                if li['name'] == "ul":
                    self.o(self.ul_item_mark + " ")
                elif li['name'] == "ol":
                    li['num'] += 1
                    self.o(str(li['num']) + ". ")
                self.start = 1
            return True

    def post_process_markdown(self, markdown):
        # Unindent reference links at the bottom
        markdown = re.sub(r'^   (\[[0-9]+\]: )', r'\1', markdown, flags=re.M)
        return markdown

    def html_to_markdown(self, html):
        text_maker = html2text.HTML2Text()
        text_maker.body_width = 0 # Turn off wrapping
        # Put all the links at the end
        text_maker.inline_links = False
        markdown = text_maker.handle(html)
        markdown = self.post_process_markdown(markdown)
        return markdown

    def clip(self, url):
        r = self.readability(url)
        m = self.html_to_markdown(r['content'])
        return "# %s\n\n[Source](%s \"Permalink to %s\")\n\n%s" % (
            r['title'], r['url'], r['title'], m)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: %s URL" % sys.argv[0])
        print()
        print("Converts the given URL to markdown")
        sys.exit(1)
    web_clipper = WebClipper()
    pyperclip.copy(web_clipper.clip(sys.argv[1]))
    print("Copied content of %s to clipboard" % sys.argv[1])

