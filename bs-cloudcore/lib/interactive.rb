################################################################################
# Interactive methods
################################################################################

module BsCloudcore
  # Control your Cloud resources
  class Base
    # Call individual methods to get chosen IDs
    #   Expects an array with 2 elements (name, ID) from method called
    #   The second element will be returned
    # param type [String] Name of object for listing
    # @return [String] Chosen ID
    def select_from_list(type)
      index = ''
      begin
        list = send('select_' + type).sort
      rescue NoMethodError, ArgumentError => e
        # Display list of possible lists to select_from_list on error
        STDERR.puts "Wrong method call, you can call the following objects with #{__method__}(OBJECT):\n\n"
        my_methods = private_methods.grep(/^select_/).map { |m| m.to_s.gsub(/^select_/, '') }.sort.join("\n")
        STDERR.puts my_methods + "\n\n"
        puts e.backtrace if @options[:debug]
        raise
      end
      if list.nil? || list.empty?
        puts 'Nothing found'
        return false
      end
      # Display formatted list
      puts "\n#{type.capitalize} list:"
      list.each_with_index { |value, idx| puts format('%2d - %s (%s)', idx, value[0], value[-1]) }
      loop do
        print "Please enter #{type} number (0): "
        index = gets.chomp.to_i
        if list[index].nil?
          STDERR.puts "Error: Incorrect #{type} number"
        else
          puts "Selected #{type} #{list[index]}" if @debug
          break
        end
      end
      list[index][-1]
    end

    private

    # Get list of availability zones
    # @return [Array] List of availability zones
    def select_availability_zone
      compute.list_zones[:body]['availabilityZoneInfo'].map { |z| zonelist << [z['zoneName'], z['zoneName']] }
    end

    # Get list of flavours
    # @return [Array] List of flavours (name, ID)
    def select_flavor
      compute.flavors.map { |f| [f.name, f.id] }
    end

    # Get list of images
    # @return [Array] List of images (name, ID)
    def select_image
      compute.images.map { |i| [i.name, i.id] }
    end

    # Get list of key pairs
    # @return [Array] List of key pairs (name, name)
    def select_keypair
      compute.key_pairs.map { |k| [k.name, k.name] }
    end

    # Get list of networks in a project
    # @return [Array] List of networks (name, ID)
    def select_network
      network.networks.map { |n| [n.name, n.id] }
    end

    # Get list of accessible projects
    #   Uses class method project_list
    # @return [Array] List of projects (name, ID)
    def select_project
      project_list.map { |id, hash| [hash['name'], id] }
    end

    # Get list of security groups
    # @return [Array] List of security groups (name, ID)
    def select_security_group
      compute.security_groups.each { |s| [s.name, s.id] }
    end

    # Get list of servers
    # @return [Array] List of servers (name, ID)
    def select_server
      compute.servers.map { |s| [s.name, s.id] }
    end

    # Get list of automation nodes
    # @return [Array] List of automation nodes (name, ID)
    def select_automation_node
      automation.agent_list.map { |id, value| [value[:display_name], id] }
    end

    # Get list of templates
    # @return [Array] List of local templates (filename, path)
    def select_template
      templatelist = []
      templatelist
    end
  end
end
