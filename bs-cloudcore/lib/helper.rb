################################################################################
# Helper methods
################################################################################

module
BsCloudcore
  # Control your Cloud resources
  class Base
    # Parse openrc file with OpenStack parameters
    # @param [String] file OpenRC file location
    def parse_openrc(file)
      file.strip!
      file = File.expand_path(file)
      unless File.file?(file)
        STDERR.puts "#{__method__}: File \"#{file}\" does not exist"
        return false
      end
      openrc = []
      File.readlines(file).each do |line|
        next unless line =~ /^export/ && line !~ /OS_PASSWORD/
        openrc << line.chomp.delete('"').split(/ +|=/)[1..-1]
      end
      openrc.map { |f| f[0].downcase! }
      openrc
    end
  end
end
