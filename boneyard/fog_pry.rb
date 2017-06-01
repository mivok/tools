#!/usr/bin/env ruby
# Extremely simple fog wrapper using pry for the interactive shell
# Written before I realized there was a 'fog' command already, but I like pry
# and using ~/.aws/config for credentials.

require 'fog'
require 'fog/core'
require 'fog/compute'
require 'fog/aws'
require 'pry'
require 'inifile'

aws_credentials = IniFile.load(
  File.join(File.expand_path('~'), ".aws", "config"))

if ARGV[0].nil?
  creds = aws_credentials['default']
else
  creds = aws_credentials["profile #{ARGV[0]}"]
end

compute = Fog::Compute.new({
  :provider => "AWS",
  :aws_access_key_id => creds['aws_access_key_id'],
  :aws_secret_access_key => creds['aws_secret_access_key'],
  :region => creds['region'] || 'us-east-1'
})

# Gimme shell
binding.pry
