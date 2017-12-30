require 'bs-cloudcore'

#  When working with sourced OpenStack openrc files, everything you need is in your environment variables
mycloud = BsCloudcore::Base.new(:api_key => ENV['OS_PASSWORD'],
                                :username => ENV['OS_USERNAME'],
                                :auth_url => File.join(ENV['OS_AUTH_URL'], 'auth/tokens'),
                                :domain_name => ENV['OS_USER_DOMAIN_NAME'],
                                :project_name => ENV['OS_PROJECT_NAME'],
                                :debug => true)

compute = mycloud.compute

# List all servers in project with ID and name
compute.servers.each do |server|
  puts "#{server.id} (#{server.name})"
end
