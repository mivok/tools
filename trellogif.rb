#!/usr/bin/env ruby
# Posts gifs to trello
#
# Get API key from: https://trello.com/1/appKey/generate
# You just want the api key, not the secret.
#
# Generate a read/write member token by going to:
# https://trello.com/1/authorize?key=YOUR_API_KEY&name=trello-gif&expiration=never&response_type=token&scope=read,write
#
# Create ~/.trellogifrc with:
#
# api_key "apikey"
# member_token "membertoken"
# board_name "Trello board name"
#
# It will post to the first list on the board
#
# Usage: trellogif.rb URL [Description of image]
#
# The description will be set to '...' if not given.
require 'mixlib/config'
require 'trello'

module TrelloConfig
  extend Mixlib::Config
end

TrelloConfig.from_file(File.expand_path('~/.trellogifrc'))

Trello.configure do |config|
  config.developer_public_key = TrelloConfig.api_key
  config.member_token = TrelloConfig.member_token
end

me = Trello::Member.find("me")
board = me.boards.select { |b| b.name == TrelloConfig.board_name }.first

raise "No board found" unless board

list = board.lists.first

name = ARGV[1..-1].join(" ")
name = "..." if name.empty?

card = Trello::Card.create(
  :list_id => list.id,
  :name => name,
  :desc => ARGV[0],
)
card.add_attachment(ARGV[0])
puts "Added"
