#!/usr/bin/env ruby
# Provision users in lastpass from a CSV file
require 'faraday'
require 'csv'
require 'json'
require 'xmlsimple'

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

users = []
CSV.foreach("users.csv", :headers => :first_row, :header_converters => :symbol) do |row|
  combinedusername="#{row[:email]}"
  if row[:name]
    combinedusername += "(#{row[:name]})"
  end
  if row[:groups]
    # Groups should be separated by ';' in the csv file
    combinedusername += "((#{row[:groups].gsub(";",",")}))"
  end
  users << combinedusername
end

response = conn.post '/enterpriseapi.php', {
  :cmd => 'batchadd',
  :cid => creds['cid'],
  :provhash => creds['provhash'],
  :createaction => 2, # Return temporary password
  :creategroups => 1, # Create groups if necessary for the user
  :users => users.join(',')
}
parsed = XmlSimple.xml_in(response.body)
userinfo = parsed['userinfo'][0]
puts "username,temp_password"
if userinfo.length > 1
  1.upto((userinfo.length - 1) / 2) do |i|
    puts "#{userinfo["username#{i}"]},\"#{userinfo["password#{i}"]}\""
  end
end
