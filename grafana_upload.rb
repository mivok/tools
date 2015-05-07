#!/usr/bin/env ruby
require 'json'
require 'net/http'
require 'uri'

token = File.read(File.expand_path('~/.grafanatoken')).strip

grafana_url = ARGV[0]
dashboard = JSON.load(File.read(File.expand_path(ARGV[1])))

uri = URI.parse("#{grafana_url}/api/dashboards/db")
req = Net::HTTP::Post.new(uri.path, initheader = {
  'Content-Type' => 'application/json',
  'Authorization' => "Bearer #{token}"
})
req.body = {"dashboard" => dashboard, "overwrite" => true}.to_json
res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end
response = JSON.load(res.body)
if response.nil?
  puts res
else
  puts "#{response['slug']}: #{response['status']}"
end
