#!/usr/bin/env ruby

################################################################################
# server.rb
#
# Create or delete a server from options, YAML file, and interactive input
################################################################################

require 'bs-cloudcore'
require 'optparse'
require 'yaml'
require 'highline/import'

# Don't buffer stdout and stderr
$stdout.sync = true
$stderr.sync = true

# Abort threads on exception
Thread.abort_on_exception = true

# Parse command-line options and/or configuration file
options = {}

args = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
  opts.on('-h', '--help', 'Show help') do
    puts opts
    exit
  end
  opts.on('-D', '--[no-]debug', 'Print debug output, default: false)') { |v| options[:debug] = v }
  opts.on('-f', '--file FILE', 'Use YAML configuration file FILE, command-line options override file options') { |v| options[:file] = File.expand_path(v) }
  opts.on('-P', '--provider PROVIDER', 'Cloud provider (default: "openstack")') { |v| options[:provider] = v }
  opts.on('-a', '--auth_url URL', 'Authentication URL (default: "https://identity-3.eu-de-1.cloud.sap:443/v3")') { |v| options[:auth_url] = v }
  opts.on('-d', '--domain DOMAIN', 'Cloud domain (default: "monsoon3")') { |v| options[:domain] = v }
  opts.on('-p', '--project PROJECT', 'Cloud project name') { |v| options[:project] = v }
  opts.on('-c', '--[no-]create', 'Create VM') { |v| options[:create] = v }
  opts.on('-l', '--flavor FLAVOR', 'Use FLAVOR for VM creation') { |v| options[:flavor] = v }
  opts.on('-i', '--image IMAGE', 'Use IMAGE ID for VM creation') { |v| options[:image] = v }
  opts.on('-k', '--keypair KEYPAIR', 'Use KEYPAIR for VM creation') { |v| options[:keypair] = v }
  opts.on('-n', '--network NETWORK', 'Use NETWORK ID for VM creation') { |v| options[:network] = v }
  opts.on('-m', '--name NAME', 'Name for VM creation') { |v| options[:name] = v }
  opts.on('-t', '--terminate VM', 'Terminate server ID') { |v| options[:terminate] = v }
  opts.on('--username USERNAME', 'Cloud username') { |v| options[:username] = v }
  opts.on('--password PASSWORD', 'Cloud password (do not use on CLI)') { |v| options[:password] = v }
  opts.on('--timeout TIMEOUT', 'Timeout in seconds') { |v| options[:timeout] = v.to_i }
end

# Print help on error
begin args.parse!
rescue OptionParser::InvalidOption => e
  STDERR.puts e.message.capitalize
  exit 1
end

# Defaults
default_options = {
  :domain => 'monsoon3',
  :auth_url => 'https://identity-3.eu-de-1.cloud.sap:443/v3',
  :debug => false,
  :timeout => 300
}

# Read configuration file, don't overwrite command-line options
unless options[:file].nil?
  unless File.exist?(options[:file])
    STDERR.puts "Error: Could not find configuration file \"#{options[:file]}\""
    exit 1
  end
  options_fromfile = YAML.load_file(options[:file])
  # Remove empty elements
  options_fromfile.reject! { |_, value| value.nil? }
  options = options_fromfile.merge(options)
end

# Merge defaults
options = default_options.merge(options)

# Set Boolean paramaters explicitely to false
%w[create debug].each do |var|
  options[:"#{var}"] ||= false
end

# Check configuration for missing essential options
options_missing = []
essential_opts = %w[username domain project]
essential_opts.each do |opt|
  options_missing << opt if options[:"#{opt}"].nil? || options[:"#{opt}"].empty?
end
if options_missing.count > 0
  plural = options_missing.count == 1 ? ' is' : 's are'
  STDERR.puts "Error: The following option#{plural} missing:\n#{options_missing.join("\n")}"
  exit 1
end

@debug = options[:debug]

# Ask for password
def pw_ask
  input = nil
  while input.nil? || input.strip.empty?
    input = ask('Enter your Cloud password: ') { |q| q.echo = '*' }
  end
  input
end

# Parse Excon errors
#
# @param [Excon::Error] error Error object
# @return [String] Error message
def errorparse(error)
  return error.message if @debug
  message = JSON.parse(error.response.data[:body]).to_hash
  field = error.class.to_s.split(/:+/).last.downcase
  message.each_key { |k| field = k if k =~ /#{field}/i }
  message[field]['message']
end

# Check server status
#
# @param [Object] object Fog object
# @param [String] state State to wait for
def check_status(object, my_state)
  my_state.downcase!
  begin
     object.wait_for { state =~ /%{my_state}/i }
   rescue Fog::Errors::TimeoutError => e
     raise e.class, "Operation timed out while #{object.class.name.split('::').last.downcase} " \
                    "was in state \"#{object.state.downcase}\", check project for errors"
   end
end

# Prompt for password if missing
if options[:password].nil? || options[:password].strip.empty?
  options[:password] = pw_ask
end

@timeout = (options[:timeout] || 60).to_i

# Initialise Cloud access
begin
  mycloud = BsCloudcore::Base.new(:api_key => options[:password],
                                  :username => options[:username],
                                  :auth_url => options[:auth_url],
                                  :domain_name => options[:domain],
                                  :project_name => options[:project],
                                  :timeout => options[:timeout],
                                  :debug => options[:debug])
rescue RuntimeError => e
  STDERR.puts e.message
  STDERR.puts 'Error: Cloud initialisation failed'
  exit 1
end

# Create server
if options[:create]
  puts 'Creating server'
  # Get create parameters interactively if missing
  %w[flavor image keypair network].each do |check|
    if options[:"#{check}"].nil?
      options[:"#{check}"] = mycloud.select_from_list(check)
    end
  end
  if options[:name].nil? || options[:name].strip.empty?
    loop do
      print 'Please enter a server name: '
      options[:name] = gets.strip
      break unless options[:name].empty?
    end
  end
  begin
    server = mycloud.compute.servers.create(
      :name => options[:name],
      :image_ref => options[:image],
      :flavor_ref => options[:flavor],
      :key_name => options[:keypair],
      :nics => [{ :net_id => options[:network] }]
    )
    # Wait until server is ready
    check_status(server, 'active')
    puts "Created server #{server.name} (#{server.id})"
    exit
  rescue Excon::Error => e
    raise e.class, errorparse(e)
  end
end

# Terminate server
if options[:terminate]
  puts 'Terminating server'
  if options[:terminate].nil? || options[:terminate].strip.empty?
    options[:terminate] = mycloud.select_from_list('server')
  end
  server = mycloud.compute.servers.find { |s| s.id == options[:terminate] }
  raise ArgumentError, 'Could not find a server with ID ' + options[:terminate] if server.nil?
  begin
    server.destroy
    # Wait until server is terminated
    check_status(server, 'unavailable|terminated')
    puts "Server #{server.id} has been terminated"
  rescue Excon::Error => e
    raise e.class, errorparse(e)
  end
end
