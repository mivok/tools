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
    :default => "header,subject,cn,san",
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

  def pretty_print_extension(e)
    values = e.value.split("\n")
    if values.length == 1
      puts "#{e.oid}: #{values[0]}"
    else
      puts "#{e.oid}:"
      values.each {|v| puts "    #{v}" unless v.empty?}
    end
  end

  def print_cert_info(certs)
    cert = certs[0] # Get the first certificate in the chain
    @config[:format].split(',').map{|f| f.downcase}.each do |fmt|
      case fmt
      when "header"
        puts "==> #{@config[:host]}"
      when "algorithm", "signature_algorithm"
        puts "Signature algorithm: #{cert.signature_algorithm}"
      when "chain"
        puts "Certificate chain:"
        certs.each do |c|
          puts "    #{c.subject}"
        end
      when "cn"
        puts "CN: #{cert.subject.to_a.find {|i| i[0] == "CN"}[1]}"
      when "expiry", "not_after"
        puts "Not After: #{cert.not_after}"
      when "extension_allexceptsan"
        # Print all extensions, but exclude SAN because we format it nicer
        # elsewhere
        cert.extensions.each do |e|
          next if e.oid == "subjectAltName"
          pretty_print_extension(e)
        end
      when "extension_all"
        cert.extensions.each do |e|
          pretty_print_extension(e)
        end
      when /^extension_/
        # Get extension mame in camelCase format
        ext_name = fmt.sub("extension_", "").gsub(/_(.)/) {|s| $1.upcase}
        ext = cert.extensions.find{|e| e.oid == ext_name}
        if ext.nil?
          puts "#{ext_name}: Not found"
        else
          pretty_print_extension(ext)
        end
      when "issuer"
        puts "Issuer: #{cert.issuer}"
      when "public_key"
        puts "Public Key:"
        puts cert.public_key
      when "modulus"
        puts "Modulus: #{cert.public_key.n.to_s(16)}"
      when "exponent"
        puts "Exponent: #{cert.public_key.e}"
      when "san"
        san_ext = cert.extensions.find {|e| e.oid == 'subjectAltName'}
        if san_ext.nil?
          puts "subjectAltNames: No SANs present"
        else
          san_domains = san_ext.value.split(', ').map{|i| i.sub('DNS:','') }
          puts "subjectAltNames:"
          san_domains.each {|d| puts "    #{d}"}
        end
      when "serial", "serial_number"
        puts "Serial: #{cert.serial}"
      when "start", "not_before"
        puts "Not Before: #{cert.not_before}"
      when "subject"
        puts "Subject: #{cert.subject}"
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
      when "version"
        puts "Version: #{cert.version}"
      when "pry"
        # For debugging or custom fields
        require 'pry'
        binding.pry
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
  cli.config[:format] = 'header,version,serial,algorithm,chain,verifychain,not_before,not_after,subject,modulus,exponent,san,extension_allexceptsan'
end
if cli.config[:expiry]
  cli.config[:format] = 'expiry'
end
ci = CertInspector.new(cli.config)
ci.run
