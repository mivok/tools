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
end

output_file = ARGV[1]
if output_file.nil?
  # Default to filename.json
  output_file = "#{File.basename(ARGV[0], File.extname(ARGV[0]))}.json"
end

File.foreach(ARGV[0]) do |line|
  url = URI(line)
  params = URI.decode_www_form(url.query)
  graph = {
    "id" => 1,
    "targets" => [
      #{ "target": "..." }
    ],
    "title" => "A graph",
    "type" => "graph",
    "span" => 6 # Half of the width of the screen
  }
  params.each do |k, v|
    case k
    when "target"
      graph["targets"] << {"target" => v}
    when "title"
      graph["title"] = v
    when "vtitle"
      graph["leftYAxisLabel"] = v
    when "from", "width", "height", "until", "areaMode", "hideLegend"
      # We ignore these
    when /[0-9]+/
      # Ignore this too (timestamp/cache buster)
    else
      raise "Unknown URL parameter: #{k} = #{v}"
    end
  end
  graphs << graph
end

# TODO - convert the graphs into rows and generate the json
rows = []
graphs.each_slice(2) do |panels|
  rows << {
    "height" => "250px",
    "panels" => panels,
    "title" => "Row"
  }
end

dashboard = {
  "title" => "Some Dashboard",
  "rows" => rows,
  "schemaVersion" => 6,
  "version" => 1
}

File.open(output_file, "w") do |f|
  f.write(JSON.pretty_generate(dashboard))
end
puts "Grafana dashboard written to: #{output_file}"
