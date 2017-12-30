################################################################################
# Automation methods
################################################################################

module BsCloudcore
  # Control your Automation nodes and jobs
  class Automation
    # Initialise automation parameters
    def initialize(cloudinit)
      arc = cloudinit.endpoints.select { |e| e.url =~ /arc/ }
      lyra = cloudinit.endpoints.select { |e| e.url =~ /lyra/ }
      @auto_hash = {
        :url_arc => arc.first.url,
        :url_lyra => lyra.first.url,
        :auth_token => cloudinit.auth_token
      }
      timeout = @timeout
      @arc_client = RubyArcClient::Client.new(@auto_hash[:url_arc], timeout)
    end

    # Return a list of existing automation agents/nodes
    #
    # @return [Hash] Automation agent/node list
    def agent_list(auth_token = @auto_hash[:auth_token])
      list = {}
      @arc_client.list_agents(auth_token).data.each do |agent|
        agent = agent.to_h
        id = agent[:agent_id]
        agent.delete(:agent_id)
        list[id] = agent
      end
      list
    end
  end
end
