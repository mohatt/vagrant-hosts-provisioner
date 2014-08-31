module VagrantPlugins
  module HostsProvisioner
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :hostname
      attr_accessor :manage_guest
      attr_accessor :manage_host
      attr_accessor :aliases
      attr_accessor :files

      def initialize
        @hostname           = UNSET_VALUE
        @manage_guest       = UNSET_VALUE
        @manage_host        = UNSET_VALUE
        @aliases            = UNSET_VALUE
        @files              = UNSET_VALUE
      end

      def finalize!
        @hostname           = nil if @hostname == UNSET_VALUE
        @manage_guest       = false if @manage_guest == UNSET_VALUE
        @manage_host        = false if @manage_host == UNSET_VALUE
        @aliases            = [] if @aliases == UNSET_VALUE
        @files              = [] if @files == UNSET_VALUE

        @aliases            = [ @aliases ].flatten
        @files              = [ @files ].flatten
      end

      def validate(machine)
        errors = []

        errors << validate_bool('manage_guest', manage_guest)
        errors << validate_bool('manage_host', manage_host)
        errors << validate_array_or_string('aliases', aliases)
        errors << validate_array_or_string('files', files)
        errors.compact!

        { "HostsProvisioner configuration" => errors }
      end

      # Checks if a option is boolean
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

      # Checks if a option is an Array
      def validate_array_or_string(key, value)
        if !aliases.kind_of?(Array) && !aliases.kind_of?(String)
          I18n.t('vagrant_hostsprovisioner.config.not_an_array_or_string', {
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
