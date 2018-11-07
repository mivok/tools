#!/usr/bin/env ruby
# Extracts a kubernetes context from a kubernetes config file, and prints it
# out as a standalone configuration file
require 'yaml'

#kubeconfig = ENV['KUBECONFIG'] || "#{ENV['HOME']}/.kube/config"
kubeconfig = "#{ENV['HOME']}/.kube/config"

data = YAML.load(File.read(kubeconfig))

context_name = ARGV[0]

context = data['contexts'].select{|c| c['name'] == context_name}[0]

out = {}
out['contexts'] = [context]

out['clusters'] = data['clusters'].select do |i|
  i['name'] == context['context']['cluster']
end

out['users'] = data['users'].select do |i|
  i['name'] == context['context']['user']
end

out['kind'] = data['kind']
out['apiVersion'] = data['apiVersion']
out['preferences'] = {}
out['current-context'] = context_name

puts YAML.dump(out)
