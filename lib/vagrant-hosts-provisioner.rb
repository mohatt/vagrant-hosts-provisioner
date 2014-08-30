require 'vagrant-hosts-provisioner/plugin'
require 'vagrant-hosts-provisioner/version'

module VagrantPlugins
  module HostsProvisioner
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end
