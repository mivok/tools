#!/usr/bin/env ruby
# Delete dashboards from grafana in bulk
# Usage: grafana_bulk_delete.rb http://grafana.example.com/ SEARCH_QUERY
# Note: this needs a grafana api token to be stored in ~/.grafanatoken
require 'json'
require 'net/http'
require 'uri'
require 'open-uri'

def search_dashboards(grafana_url, query)
  query = URI::encode(query)
  uri = URI.parse("#{grafana_url}/api/search?limit=0&query=#{query}")
  response = Net::HTTP.get_response(uri)
  JSON.load(response.body)
end

def delete_dashboard(grafana_url, slug, token)
  uri = URI.parse("#{grafana_url}/api/dashboards/db/#{slug}")
  req = Net::HTTP::Delete.new(uri.path, initheader = {
    'Authorization' => "Bearer #{token}"
  })
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  JSON.load(response.body)
end

token = File.read(File.expand_path('~/.grafanatoken')).strip

if ARGV[1].nil?
  puts "Usage: #{$0} URL SEARCH"
  puts "Bulk delete dashboards"
end

grafana_url = ARGV[0]
query = ARGV[1]

response = search_dashboards(grafana_url, query)
puts "=> Deleting the following dashboards"
response['dashboards'].each do |d|
  puts "#{d['title']}"
end

answer = ''
until ['y', 'n'].include?(answer)
  print "OK to delete (Y/N)? "
  answer = $stdin.gets.downcase[0]
end
if answer != "y"
  puts "Exiting..."
  exit 1
end

response['dashboards'].each do |d|
  puts "=> Deleting #{d['slug']}"
  response = delete_dashboard(grafana_url, d['slug'], token)
  if response['title'] != d['title']
    puts response
    puts "ERROR: unable to delete dashboard"
    exit 1
  else
    puts "OK"
  end
end
