################################################################################
# Openstack initialisation
################################################################################

# Control your Cloud resources
module BsCloudcore
  # Control your Converged Cloud resources
  class BsOpenstack
    # @!attribute [r] domain_id
    # @return [String] Domain ID hash
    attr_reader :domain_id

    # Initialise OpenStack connection parameters
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
      # Create an hash with all parameters needed for OpenStack
      @os_hash = {
        :openstack_username => options[:username],
        :openstack_api_key => options[:api_key],
        :connection_options => { :connect_timeout => options[:timeout].to_i, :debug_request => options[:debug], :debug_response => options[:debug] },
        :provider => 'openstack'
      }

      # Use either *_name or *_id
      @os_hash[:openstack_auth_url] = if options[:auth_url] =~ %r{auth/tokens$}
                                        options[:auth_url]
                                      else
                                        File.join(options[:auth_url], 'auth/tokens')
                                      end
      @os_hash[:openstack_domain_name] = options[:domain_name] unless options[:domain_name].nil?
      @os_hash[:openstack_domain_id] = options[:domain_id] unless options[:domain_id].nil?
      @os_hash[:openstack_project_name] = options[:project_name] unless options[:project_name].nil?
      @os_hash[:openstack_project_id] = options[:project_id] unless options[:project_id].nil?
      @domain_id = if options[:domain_id].nil?
                     identity.current_tenant['domain']['id']
                   else
                     options[:domain_id]
                   end
    end

    # Initialise compute object
    #
    # @param [Hash] os_hash Configuration parameters
    # @return [Fog::Compute::OpenStack]
    def compute(os_hash = @os_hash)
      Fog::Compute.new(os_hash)
    end

    # Initialise dns object
    #
    # @param [Hash] os_hash Configuration parameters
    # @return [Fog::DNS::OpenStack]
    def dns(os_hash = @os_hash)
      Fog::DNS.new(os_hash)
    end

    # Initialise identity object
    #
    # @param [Hash] os_hash Configuration parameters
    # @return [Fog::Identity::OpenStack]
    def identity(os_hash = @os_hash)
      Fog::Identity.new(os_hash)
    end

    # Initialise image object
    #
    # @param [Hash] os_hash Configuration parameters
    # @return [Fog::Image::OpenStack]
    def image(os_hash = @os_hash)
      Fog::Image::OpenStack.new(os_hash)
    end

    # Initialise network object
    #
    # @param [Hash] os_hash Configuration parameters
    # @return [Fog::Network::OpenStack]
    def network(os_hash = @os_hash)
      Fog::Network.new(os_hash)
    end

    # Initialise storage object
    #
    # @param [Hash] os_hash Configuration parameters
    # @return [Fog::Storage::OpenStack]
    def storage(os_hash = @os_hash)
      Fog::Storage.new(os_hash)
    end
  end
end
