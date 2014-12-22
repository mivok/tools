#!/usr/bin/env ruby
# Adds users to groups in lastpass in bulk
# Note: does not automatically share folders
#
# Users are read in from a file, one email address per line
# The group name is specified on the command line.
require 'faraday'
require 'json'
require 'xmlsimple'

if ARGV[0].nil? or ARGV[1].nil?
  puts "Usage: #{$0} GROUPNAME FILENAME"
  exit 1
end

group = ARGV[0]
filename = ARGV[1]

# URL to lastpass API
# For testing - ruby -run -e httpd . -p 9090
#url = "http://127.0.0.1:9090"
# For prod
url = "https://lastpass.com"

# Format:
# { "cid": "...", "provhash": "..." }
creds = JSON.parse(File.read("credentials.json"))

conn = Faraday.new(:url => url) do |faraday|
  faraday.request :url_encoded
  #faraday.response :logger
  faraday.adapter Faraday.default_adapter
  faraday.options[:timeout] = 3600
end

puts "Group: #{group}"
puts "File: #{filename}"
puts

File.read(filename).split.each do |u|
  response = conn.post '/enterpriseapi.php', {
    :cmd => 'changegrp',
    :cid => creds['cid'],
    :provhash => creds['provhash'],
    :username => u,
    :add0 => group
  }
  resp = XmlSimple.xml_in(response.body)
  puts "#{u} => #{resp['rc']}"
end
