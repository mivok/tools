#!/usr/bin/env python3
# Converts an evernote enex export into markdown. It mostly uses html2text,
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
import xml.etree.ElementTree as ET

import html2text
import bs4

def tag_callback(self, tag, attrs, start):
    """This lets us override existing functionality in html2text"""
    if tag == 'li':
        # The only change from html2text here is the indentation of the list
        # (I want lists to start at column 1)
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
            self.o("  " * (nest_count - 1))
            if li['name'] == "ul":
                self.o(self.ul_item_mark + " ")
            elif li['name'] == "ol":
                li['num'] += 1
                self.o(str(li['num']) + ". ")
            self.start = 1
        return True

def process_content(text):
    soup = bs4.BeautifulSoup(text, "html.parser")

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

    # Fix badly nested lists
    # This makes <ul><li>Item</li><ul>.... into <ul><li>Item<ul>...</li>
    nested_lists = soup.select('ul > ul')
    for u in nested_lists:
        prev = u.previous_sibling
        if prev and prev.name == 'li':
            # Fold the ul into the previous li element
            prev.append(u.extract())
        else:
            # There isn't a previous li item to fold into, which means we
            # ended up with a list that was nested two levels at once. This is
            # probably a mistake, so make sure the list level only indents one
            # level at once.
            u.unwrap()

    # Fix fake/bold headings
    bold_headers = soup.select('div span[style="font-weight: bold;"],b')
    for h in bold_headers:
        if len(h.parent.contents) == 1: # Only child
            # The > selector didn't work in the soup.select above, so check it
            # here
            if h.parent.name == 'div':
                text = h.text
                p = h.parent
                if text.strip() != '':
                    # Only add non-blank headers
                    p.name = 'h2'
                    p.clear()
                    p.append(text)
                else:
                    # If we have an empty line of bold text, it isn't a header
                    # and should just be removed
                    p.extract()

    #print(soup.prettify())

    ## Do the conversion here
    text_maker = html2text.HTML2Text()
    text_maker.single_line_break = True
    text_maker.inline_links = False
    text_maker.tag_callback = tag_callback

    markdown = text_maker.handle(str(soup))

    ## Post-process markdown

    # Convert indented code blocks to code fences
    lines = []
    in_code = False
    prev_line = ''
    for line in markdown.split("\n"):
        if line[0:4] == '    ':
            if in_code:
                lines.append(line[4:])
            elif prev_line != '':
                lines.append(line)
            else: # Code should have a blank line before it
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
        prev_line = line

    markdown = "\n".join(lines)

    # Fix footnote links
    markdown = re.sub(r'\n   (\[\d+\]:)[ \n](.*)\n', r'\n\1 \2', markdown)
    # Fix trailing newlines
    markdown = markdown.rstrip("\n")

    return markdown

if __name__ == '__main__':
    tree = ET.parse(sys.argv[1])
    root = tree.getroot()

    for note_element in root:
        if note_element.tag != 'note':
            # All tags should be notes, but this is a quick guard to skip
            # anything that isn't a note
            continue
        note = {}
        for child in note_element:
            if child.tag == 'title':
                note['title'] = child.text
            elif child.tag == 'tag':
                note.setdefault('tags', []).append(child.text)
            elif child.tag == 'content':
                note['markdown'] = process_content(child.text)
        print(note['title'])
        fh = open("%s.md" % note['title'], "w")
        fh.write("# %s\n\nTags: %s\n\n%s" % (
            note['title'],
            ' '.join(["#%s" % i for i in note['tags']]),
            note['markdown']
        ))
