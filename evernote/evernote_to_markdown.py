#!/usr/bin/env python3
# Converts an evernote html export into markdown. It mostly uses html2text,
# with some pre and post processing to make things look right. Pre-processing
# is done with beautiful soup.
#
# Note: this is only really suitable for handwritten evernote files, and
# probably won't work well on, say, web clippings.
#
# - It converts evernote code blocks (with the ``` shortcut on the mac client)
# into markdown code blocks.
# - It converts any lines consisting entirely of bold text into h2 headers.
# This lets you use bold to fake headers in evernote and have it come out
# pretty close in markdown.
# - Some other minor cleanup is done

import re
import sys

import html2text
import bs4

with open(sys.argv[1]) as fh:
    soup = bs4.BeautifulSoup(fh.read(), "html.parser")

## Preprocess evernote file

# Fix codeblocks
codeblocks = soup.select('div[style$="-en-codeblock:true;"]')
for cb in codeblocks:
    text = []
    for c in cb.children:
        text.append(c.text)
    cb.name = 'pre'
    del cb['style']
    cb.clear()
    cb.append("\n".join(text))

# Fix extra line breaks
extra_breaks = soup.select('div > br')
for b in extra_breaks:
    if len(b.parent.contents) == 1: # Only child
        b.extract()

# Fix fake/bold headings
bold_headers = soup.select('div span[style="font-weight: bold;"],b')
for h in bold_headers:
    if len(h.parent.contents) == 1: # Only child
        # The > selector didn't work in the soup.select above, so check it
        # here
        if h.parent.name == 'div':
            text = h.text
            p = h.parent
            p.name = 'h2'
            p.clear()
            p.append(text)

## Do the conversion here
text_maker = html2text.HTML2Text()
text_maker.single_line_break = True
text_maker.inline_links = False

markdown = text_maker.handle(str(soup))

## Post-process markdown

# Convert indented code blocks to code fences
lines = []
in_code = False
for line in markdown.split("\n"):
    if line[0:4] == '    ':
        if in_code:
            lines.append(line[4:])
        else:
            lines.append('```')
            # html2text likes to add a blank line at the beginning of code
            # blocks, so make sure we skip it if it's present
            if not line.isspace():
                lines.append(line[4:])
            in_code = True
    else:
        if in_code:
            lines.append('```')
            if line != '':
                # Make sure there's an extra blank line at the end of code
                # blocks because html2text doesn't seem to want to add one
                lines.append('')
            in_code = False
        lines.append(line)

markdown = "\n".join(lines)

# Fix footnote links
markdown = re.sub(r'\n   (\[\d+\]:)[ \n](.*)\n', r'\n\1 \2', markdown)
# Fix trailing newlines
markdown = markdown.rstrip("\n")

print(markdown)
