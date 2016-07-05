#!/usr/bin/env ruby
require 'date'
require 'socket'
require 'openssl'
require 'mixlib/cli'

class AppCLI
  include Mixlib::CLI

  banner "Usage: #{File.basename($0)} [options] HOSTNAME"

  option :port,
    :short => "-p PORT",
    :long => "--port PORT",
    :default => 443,
    :description => "Port to connect to"

  option :sni,
    :short => "-s",
    :long => "--[no-]sni",
    :boolean => true,
    :default => true,
    :description => "Enable/disable SNI"

  option :format,
    :short => "-o FMT",
    :long => "--output FMT",
    :default => "header,cn,san",
    :description => "Specify what fields to display"

  option :all,
    :short => "-a",
    :long => "--all",
    :boolean => true,
    :description => "Print out all info on a certificate"

  option :expiry,
    :short => "-e",
    :long => "--expiry",
    :boolean => true,
    :description => "Just print out the certificate expiry date"

  option :help,
    :short => "-?",
    :long => "--help",
    :description => "Show this message",
    :on => :tail,
    :boolean => true,
    :show_options => true,
    :exit => 0
end

class CertInspector
  def initialize(config)
    @config = config
  end

  def run
    certs = get_cert_connect(@config[:host], @config[:port])
    print_cert_info(certs)
  end

  def get_cert_connect(host, port)
    tcp_client = TCPSocket.new(host, port)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
    # SNI
    if @config[:sni]
      ssl_client.hostname = host
    end
    ssl_client.connect
    certs = ssl_client.peer_cert_chain
    ssl_client.close
    certs
  end

  def print_cert_info(certs)
    cert = certs[0] # Get the first certificate in the chain
    @config[:format].split(',').map{|f| f.downcase}.each do |fmt|
      case fmt
      when "header"
        puts "==> #{@config[:host]}"
      when "cn"
        puts "CN: #{cert.subject.to_a.find {|i| i[0] == "CN"}[1]}"
      when "san"
        san_ext = cert.extensions.find {|e| e.oid == 'subjectAltName'}
        if san_ext.nil?
          puts "subjectAltNames: No SANs present"
        else
          san_domains = san_ext.to_a[1].split(', ').map{|i| i.sub('DNS:','') }
          puts "subjectAltNames:"
          san_domains.each {|d| puts "    #{d}"}
        end
      when "expiry"
        puts "expiry: #{cert.not_after}"
      when "verifychain"
        valid = true
        parent = nil
        certs.reverse.each do |c|
        if parent
          valid &= c.verify(parent.public_key)
        end
          parent = c
        end
        puts "Chain Valid: #{valid}"
      when "chain"
        puts "Certificate chain:"
        certs.each do |c|
          puts "    #{c.subject}"
        end
      else
        puts "Unknown format column: #{fmt}"
      end
    end
  end
end

cli = AppCLI.new
argv = cli.parse_options
cli.config[:host] = argv[0]
if cli.config[:host].nil?
  puts "You must specify a hostname"
  puts cli.opt_parser
  exit 1
end
if cli.config[:all]
  cli.config[:format] = 'header,cn,san,expiry,chain,verifychain'
end
if cli.config[:expiry]
  cli.config[:format] = 'expiry'
end
ci = CertInspector.new(cli.config)
ci.run
