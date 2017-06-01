#!/usr/bin/env ruby
# Combines multiple dashboards into one.
# Usage: grafana_combine.rb http://grafana.example.com/ SEARCH_QUERY NEW_TITLE
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

def get_dashboard(grafana_url, slug)
  uri = URI.parse("#{grafana_url}/api/dashboards/db/#{slug}")
  response = Net::HTTP.get_response(uri)
  JSON.load(response.body)['model']
end

def upload_dashboard(grafana_url, dashboard, token)
  uri = URI.parse("#{grafana_url}/api/dashboards/db")
  req = Net::HTTP::Post.new(uri.path, initheader = {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{token}"
  })
  req.body = {"dashboard" => dashboard, "overwrite" => true}.to_json
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  JSON.load(response.body)
end

token = File.read(File.expand_path('~/.grafanatoken')).strip

if ARGV[2].nil?
  puts "Usage: #{$0} URL SEARCH NEW_TITLE"
  puts "Combines multiple dashboards into one"
end

grafana_url = ARGV[0]
query = ARGV[1]
new_title = ARGV[2]

response = search_dashboards(grafana_url, query)
count = 1
panels = []
response['dashboards'].each do |d|
  puts "=> #{d['title']}"
  dashboard = get_dashboard(grafana_url, d['slug'])
  dashboard['rows'].each do |row|
    row['panels'].each do |panel|
      puts panel['title']
      panel['id'] = count
      count += 1
      panels << panel
    end
  end
end

rows = []
panels.each_slice(2) do |panels|
  rows << {
    "height" => "250px",
    "panels" => panels,
    "title" => "Row"
  }
end

new_dashboard = {
  "title" => new_title,
  "rows" => rows,
  "refresh" => false,
  "schemaVersion" => 6,
  "version" => 1
}

puts "Uploading new dashboard..."
response = upload_dashboard(grafana_url, new_dashboard, token)
if response['status'] != 'success'
  puts response
  puts "ERROR: Exiting"
  exit 1
else
  puts "Success"
  puts response['slug']
end
