#!/usr/bin/env ruby
# Convert terraform files written for terraform 0.6 to terraform 0.7+
# Note: this is a very naive script that fixes some issues encountered with
# 0.6 scripts, and it probably won't work in every situation. Changes made
# should be reviewed after running the script.
#
# Usage:
# cd terraform_directory
# ./terraform_0.6_to_0.7.rb
#
# It will run on all .tf and .tfvars in the current directory. Any modified
# files will have their names printed out, similar to terraform fmt.

tf_files = Dir["*.tf", "*.tf_*"]
tfvars_files = Dir["*.tfvars"]

tf_files.each do |f|
  content = File.read(f)
  orig_content = content.dup
  # Convert var.foo.var into var.foo["bar"]
  content.gsub!(/var\.([a-zA-Z0-9_-]+)\.([a-zA-Z0-9_-]+)/m, 'var.\1["\2"]')
  # Convert terraform_remote_state.foo.output.bar to
  # terraform_remote_state.foo.bar
  content.gsub!(/terraform_remote_state\.([a-zA-Z0-9_-]+)\.output\.([a-zA-Z0-9_-]+)/m, 'terraform_remote_state.\1.\2')
  # Convert some resources to data sources
  data_sources = [
    "atlas_artifact",
    "template_file",
    "template_cloudinit_config",
    "tls_cert_request",
    "terraform_remote_state"
  ]
  data_sources.each do |d|
    content.gsub!(/resource "#{d}"/, "data \"#{d}\"")
    content.gsub!(/\{#{d}\./, "{data.#{d}.")
  end

  if content != orig_content
    puts f
    File.write(f, content)
  end
end

tfvars_files.each do |f|
  maps = {}
  out = []
  changed = false
  File.foreach(f) do |line|
    # Convert maps
    m = line.match(/([a-zA-Z0-9_-]+)\.([a-zA-Z0-9_-]+) ?= ?(.*$)/)
    if m
      changed = true
      unless maps[m[1]]
        maps[m[1]] = {}
        # Placeholder for where the map should be in the output
        out << "### MAP: #{m[1]}"
      end
      maps[m[1]][m[2]] = m[3]
    else
      out << line
    end
  end
  if changed
    puts f
    fh = open(f, "w")
    out.each do |line|
      m = line.match(/^### MAP: (.*)$/)
      if m
        fh.write("#{m[1]} = {\n")
        maps[m[1]].each do |k, v|
          fh.write("  #{k} = #{v}\n")
        end
        fh.write("}\n")
      else
        fh.write(line)
      end
    end
  end
end

