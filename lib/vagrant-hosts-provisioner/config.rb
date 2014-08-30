module VagrantPlugins
  module HostsProvisioner
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :hostname
      attr_accessor :manage_guest
      attr_accessor :manage_host
      attr_accessor :aliases

      def initialize
        @hostname           = UNSET_VALUE
        @manage_guest       = UNSET_VALUE
        @manage_host        = UNSET_VALUE
        @aliases            = UNSET_VALUE
      end

      def finalize!
        @hostname           = nil if @hostname == UNSET_VALUE
        @manage_guest       = false if @manage_guest == UNSET_VALUE
        @manage_host        = false if @manage_host == UNSET_VALUE
        @aliases            = [] if @aliases == UNSET_VALUE
        @aliases            = [ @aliases ].flatten
      end

      def validate(machine)
        errors = []

        errors << validate_bool('manage_guest', manage_guest)
        errors << validate_bool('manage_host', manage_host)
        errors.compact!

        # check if aliases option is an Array
        if !aliases.kind_of?(Array) && !aliases.kind_of?(String)
          errors << I18n.t('vagrant_hostsprovisioner.config.not_an_array_or_string', {
            :config_key    => 'aliases',
            :invalid_class => aliases.class.to_s,
          })
        end

        errors.compact!
        { "HostsProvisioner configuration" => errors }
      end

      def validate_bool(key, value)
        if ![TrueClass, FalseClass].include?(value.class) && value != UNSET_VALUE
          I18n.t('vagrant_hostsprovisioner.config.invalid_bool', {
            :config_key    => key,
            :invalid_class => value.class.to_s
          })
        else
          nil
        end
      end

    end
  end
end
