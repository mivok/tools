#!/usr/bin/env python3
# Converts a tiddlywiki json export to individual files
# Tags and appropriate metadata is added inline
import json
import sys

with open(sys.argv[1]) as fh:
    tiddlers = json.load(fh)

for tiddler in tiddlers:
    title = tiddler['title']
    extension = '.tid'
    if 'type' in tiddler:
        if tiddler['type'] in ['text/x-markdown', 'text/markdown']:
            extension = '.md'
    filename = title.replace('/', '_') + extension
    print(filename)
    with open(filename, 'w') as fh:
        fh.write(tiddler.get('text', ''))
        if 'tags' in tiddler:
            tags = []
            in_multi_tag = False
            curr_tag = ''
            for tag_part in tiddler['tags'].split():
                if in_multi_tag:
                    if tag_part.endswith(']]'):
                        # Separate tags with _ so we can have single word tags
                        # in markdown
                        curr_tag = curr_tag + '_' + tag_part.rstrip(']]')
                        tags.append(curr_tag)
                        in_multi_tag = False
                    else:
                        curr_tag = curr_tag + ' ' + tag_part
                elif tag_part.startswith('[['):
                    curr_tag = tag_part.lstrip('[[')
                    in_multi_tag = True
                else:
                    tags.append(tag_part)
            fh.write("\n\n")
            fh.write(' '.join([f"#{tag}" for tag in tags]))
