require File.expand_path("../hosts", __FILE__)

module VagrantPlugins
  module HostsProvisioner
    class Provisioner < Vagrant.plugin('2', :provisioner)

      def initialize(machine, config)
        @hosts = Hosts.new(machine, config)
        super
      end

      def provision
        @hosts.add
      end

    end
  end
end
