#!/usr/bin/env ruby
# Takes in a file with a list of graphite graph URLs, and spits out a json
# file suitable for importing into grafana.
require 'uri'
require 'json'

graphs = []

if ARGV[0].nil?
  puts "Usage: #{$0} INPUT_FILE [OUTPUT_FILE]"
  puts
  puts "INPUT_FILE should be a text file containing graphite URLs, one per line"
  puts "OUTPUT_FILE is optional, and defaults to INPUT_FILE.json"
  puts
  puts "Optionally, the first line of the file can be a title for the dashboard"
end

output_file = ARGV[1]
if output_file.nil?
  # Default to filename.json
  output_file = "#{File.basename(ARGV[0], File.extname(ARGV[0]))}.json"
end

title = "Some dashboard"
graph_id = 1
File.foreach(ARGV[0]) do |line|
  unless line.start_with?('http')
    title = line.strip
    next
  end
  url = URI(line)
  params = URI.decode_www_form(url.query)
  graph = {
    "id" => graph_id,
    "targets" => [
      #{ "target": "..." }
    ],
    "grid" => {},
    "title" => "A graph",
    "type" => "graph",
    "span" => 6 # Half of the width of the screen
  }
  graph_id += 1
  params.each do |k, v|
    case k
    when "target"
      graph["targets"] << {"target" => v}
    when "title"
      graph["title"] = v
    when "vtitle"
      graph["leftYAxisLabel"] = v
    when "yMin"
      graph["grid"]["leftMin"] = v
    when "yMax"
      graph["grid"]["leftMax"] = v
    when "from", "width", "height", "until", "areaMode", "hideLegend",
      "drawNullAsZero", "lineWidth", "lineMode"
      # We ignore these
    when /[0-9]+/
      # Ignore this too (timestamp/cache buster)
    else
      raise "Unknown URL parameter: #{k} = #{v}"
    end
  end
  graphs << graph
end

rows = []
graphs.each_slice(2) do |panels|
  rows << {
    "height" => "250px",
    "panels" => panels,
    "title" => "Row"
  }
end

dashboard = {
  "title" => title,
  "rows" => rows,
  "schemaVersion" => 6,
  "version" => 1
}

File.open(output_file, "w") do |f|
  f.write(JSON.pretty_generate(dashboard))
end
puts "Grafana dashboard written to: #{output_file}"
