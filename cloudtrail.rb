#!/usr/bin/env ruby
# Copyright (c) 2014 Mark Harrison
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Filter and parse cloudtrail logs for interesting events
#
# Example usage:
#
#   aws s3 cp --recursive \
#       s3://bucketname/AWSLogs/1234567890/CloudTrail/us-east-1/2014/05 .
#   gunzip *.gz
#   ./cloudtrail.rb bob *.json
#
# Example output:
# 2014-06-02T16:42:27Z: bob: RunInstances i-1234abcd
# 2014-06-02T16:45:59Z: bob: AssignPrivateIpAddresses
# 2014-06-02T16:52:47Z: bob: RunInstances i-1234abcd
# 2014-06-02T17:02:30Z: bob: AttachVolume
# 2014-06-02T16:59:25Z: bob: AssignPrivateIpAddresses
# 2014-06-02T17:37:54Z: bob: TerminateInstances i-1234abcd
# 2014-06-02T17:48:34Z: bob: RunInstances i-1234abcd
# 2014-06-02T17:53:00Z: bob: AssignPrivateIpAddresses
# 2014-06-02T17:52:01Z: bob: RunInstances i-1234abcd
# 2014-06-02T18:06:27Z: bob: AssignPrivateIpAddresses
# 2014-06-02T18:07:48Z: bob: AttachVolume
# 2014-06-02T20:19:44Z: bob: TerminateInstances i-1234abcd

require 'json'

username = ARGV.shift

if username.nil? or ARGV.empty?
  puts "Usage: #{$0} USERNAME FILENAME [FILENAME ...]"
  puts
  puts "Filter and parse cloudtrail logs for interesting events"
  puts
  puts "Username is the username you want to filter for activity on and is a"
  puts "regular expession. Put '.' as the first parameter to get activity for"
  puts "all users."
  exit -1
end

ARGV.each do |f|
  data = JSON.load(File.read(f))
  data["Records"].each do |r|
    # Skip uninteresting stuff
    next if r["eventName"].match(/^(Get|Describe|List|CreateTags$)/)
    next unless r["userIdentity"]["userName"].match(username) # can be regex

    # Add extra information such as instance IDs for certain events
    data = ""
    if r["eventName"].match(/^(Run|Terminate)Instances$/)
      data = r["responseElements"]["instancesSet"]["items"].map {
        |i| i["instanceId"] }.join(",")
    end
    puts "#{r["eventTime"]}: #{r["userIdentity"]["userName"]}: " +
      "#{r["eventName"]} #{data}"
  end
end
