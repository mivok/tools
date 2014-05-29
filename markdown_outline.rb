#!/usr/bin/env ruby
# Takes a markdown file as input and prints out all of the headers as a
# bulleted list.
require 'kramdown'

filename = ARGV[0]
if filename.nil?
  puts "Usage: md_outline.rb [FILENAME]"
  puts "Prints an outline of a markdown document as a markdown bulleted list"
  exit 1
end

def expand_headers(elements)
  headers = []
  for e in elements
    if e.type == :header
      headers.push("#{'  ' * (e.options[:level] - 1)}* #{e.options[:raw_text]}")
    end
  end
  headers
end

text = File::open(filename).read
doc = Kramdown::Document.new(text)

outline = expand_headers(doc.root.children)
puts outline
