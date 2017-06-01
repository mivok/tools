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

doc = Kramdown::Document.new(File.read(filename))
puts doc.root.children.select{ |e| e.type == :header }.map{
      |e| "#{'  ' * (e.options[:level] - 1)}* #{e.options[:raw_text]}"}
