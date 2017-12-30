################################################################################
# Azure initialisation
################################################################################

# Control your Cloud resources
module BsCloudcore
  # Control your Azure resources
  class BsAzure
    # Initialise Azure connection parameters
    #
    # @param [Hash] options Configuration parameters
    # @option options [Bool] :debug (false) Print debug output
    # @option options [Int] :timeout (60) Timeout in seconds
    def initialize(options)
      # Azure initialisation goes here
      @az_hash = {
        :connection_options => { :connect_timeout => options[:timeout].to_i, :debug_request => options[:debug], :debug_response => options[:debug] }
      }
    end

    # Initialise compute object
    #
    # @param [Hash] az_hash Configuration parameters
    # @return [Fog::Compute::Azure]
    def compute(az_hash = @az_hash)
      Fog::Compute.new(az_hash)
    end

    # Initialise dns object
    #
    # @param [Hash] az_hash Configuration parameters
    # @return [Fog::DNS::Azure]
    def dns(az_hash = @az_hash)
      Fog::DNS.new(az_hash)
    end

    # Initialise identity object
    #
    # @param [Hash] az_hash Configuration parameters
    # @return [Fog::Identity::Azure]
    def identity(az_hash = @az_hash)
      Fog::Identity.new(az_hash)
    end

    # Initialise image object
    #
    # @param [Hash] az_hash Configuration parameters
    # @return [Fog::Image::Azure]
    def image(az_hash = @az_hash)
      Fog::Image.new(az_hash)
    end

    # Initialise network object
    #
    # @param [Hash] az_hash Configuration parameters
    # @return [Fog::Network::Azure]
    def network(az_hash = @az_hash)
      Fog::Network.new(az_hash)
    end

    # Initialise storage object
    #
    # @param [Hash] az_hash Configuration parameters
    # @return [Fog::Storage::Azure]
    def storage(az_hash = @az_hash)
      Fog::Storage.new(az_hash)
    end
  end
end
