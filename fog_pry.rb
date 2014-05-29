#!/usr/bin/env ruby
# Extremely simple fog wrapper using pry for the interactive shell
# Written before I realized there was a 'fog' command already, but I like pry
# and using ~/.aws/config for credentials.

require 'fog'
require 'fog/core'
require 'fog/compute'
require 'fog/aws'
require 'pry'
require 'chef_metal/aws_credentials' # Cheat on how to get credentials

aws_credentials = ChefMetal::AWSCredentials.new
aws_credentials.load_default

creds = aws_credentials.default
# creds = aws_credentials["profile"]

compute = Fog::Compute.new({
  :provider => "AWS",
  :aws_access_key_id => creds[:access_key_id],
  :aws_secret_access_key => creds[:secret_access_key]
})

# Gimme shell
binding.pry
