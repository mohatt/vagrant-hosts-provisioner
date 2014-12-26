require_relative 'action/add'
require_relative 'action/remove'

module VagrantPlugins
  module HostsProvisioner
    module Action
      include Vagrant::Action::Builtin

      def self.add
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Add
        end
      end

      def self.remove
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Remove
        end
      end

    end
  end
end
