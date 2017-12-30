################################################################################
# Module definition and Base class for initialisation
################################################################################

require 'json'
require 'fileutils'
require 'fog/openstack'
require 'ruby-arc-client'

require File.join(File.dirname(__FILE__), 'helper')
require File.join(File.dirname(__FILE__), 'interactive')
require File.join(File.dirname(__FILE__), 'bsopenstack')
require File.join(File.dirname(__FILE__), 'bsazure')
require File.join(File.dirname(__FILE__), 'automation')

# Initialize an API connection to Converged Cloud. Provides classes and methods to control your projects
module BsCloudcore
  # Control your Cloud resources
  class Base
    # @!attribute [r] timeout
    # @return [Fixnum] HTTP read/write timeout
    attr_reader :timeout

    # @!attribute [r] domain_id
    # @return [String] Domain ID
    attr_reader :domain_id

    # Provide a new Cloud connection via password.
    #   Use either *_name or *_id where available, e.g. :domain_name
    #
    # @param [Hash] options Configuration parameters
    # @option options [String] :api_key Password/API key
    # @option options [String] :auth_url Authorisation URL
    # @option options [Bool] :debug (false) Print debug output
    # @option options [String] :domain_name ('monsoon3') Domain name
    # @option options [String] :domain_id Domain ID
    # @option options [String] :provider (openstack) Cloud provider
    # @option options [String] :project_name ('BS-Automation') Project name
    # @option options [String] :project_id Project ID
    # @option options [String] :region ('eu-de-1') Project region
    # @option options [Int] :timeout (300) Timeout in seconds
    # @option options [String] :username User name
    def initialize(options)
      # Set defaults
      default_options = {
        :debug => false,
        :domain_name => 'monsoon3',
        :project_name => 'BS-Automation',
        :provider => 'openstack',
        :region => 'eu-de-1',
        :timeout => 60
      }
      @options = default_options.merge(options)

      # Check input
      input_check
      Fog.timeout = @options[:timeout]
      @cloudinit = cloudinit(@options)
      @domain_id = @cloudinit.domain_id
    end

    # Multi-cloud initialisation
    #
    # @param [Hash] options (@options) Configuration options
    # @return []
    def cloudinit(options = @options)
      @cloudinit = case @options[:provider].downcase
                   when 'openstack'
                     BsCloudcore::BsOpenstack.new(options)
                   when 'azure'
                     BsCloudcore::BsAzure.new(options)
                   end
    rescue Excon::Error => e
      raise e.message if @options[:debug]
      message = JSON.parse(e.response.data[:body]).to_hash
      raise message['error']['message']
    end

    # Create compute object
    #
    # @return [Object] Fog::Compute object
    def compute
      @cloudinit.compute
    end

    # Create dns object
    #
    # @return [Object] Fog::DNS object
    def dns
      @cloudinit.dns
    end

    # Create identity object
    #
    # @return [Object] Fog::Identity object
    def identity
      @cloudinit.identity
    end

    # Create image object
    #
    # @return [Object] Fog::Image object
    def image
      @cloudinit.image
    end

    # Create network object
    #
    # @return [Object] Fog::Network object
    def network
      @cloudinit.network
    end

    # Create storage object
    #
    # @return [Object] Fog::Storage object
    def storage
      @cloudinit.storage
    end

    # Return a simplified list of active projects
    #
    # @param [Object] keystone Fog::Identity object
    # @return [Hash] Project list
    def project_list(keystone = @identity)
      prj_list = {}
      keystone.auth_projects.data[:body]['projects'].each do |project|
        skip unless project['enabled'] == true && project['is_domain'] == false
        prj_list[(project['id']).to_s] = {}
        project.each do |k, v|
          next if k =~ /^(id|is_domain|enabled)$/
          prj_list[(project['id']).to_s][k.to_s] = v
        end
      end
      prj_list
    end

    # Check input to initialisation
    def input_check
      @options[:timeout] = @options[:timeout].to_i
      @options[:timeout] = 300 if @options[:timeout] <= 0
      @options[:timeout] = 3600 if @options[:timeout] > 3600
      raise 'Username missing' if @options[:username].nil? || @options[:username].strip.empty?
      raise 'Password/API key missing' if @options[:api_key].nil? || @options[:api_key].strip.empty?
    end

    # Initialise automation class
    #
    # @return [Object]
    def automation
      Automation.new(@cloudinit.identity)
    end
  end
end
