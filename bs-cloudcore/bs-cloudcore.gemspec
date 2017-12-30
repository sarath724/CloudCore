require File.expand_path('../lib/version', __FILE__)
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'bs-cloudcore'
  spec.version = BsCloudcore::VERSION
  spec.licenses = ['Nonstandard']
  spec.date = '2017-12-14'
  spec.summary = 'Cloud library for BSS'
  spec.description = 'Library for Cloud management based on Fog and Terraform'
  spec.authors = ['BS Automation team', 'Walter Schiessberg']
  spec.email = %w[DL_53E9CC37DF15DB49ED000012@exchange.sap.corp walter.schiessberg@sap.com]
  spec.homepage = 'https://github.wdf.sap.corp/bs-automation/bs-cloudcore'
  spec.files = Dir['lib/**/*']
  spec.extra_rdoc_files = ['README.md']
  spec.require_paths = %w[lib examples]
  spec.required_ruby_version = Gem::Requirement.new('>= 2.2.1'.freeze)
  spec.add_dependency 'fog-openstack', '~> 0.1', '>= 0.1.22'
  spec.add_dependency 'ruby-arc-client', '~> 0'
end
