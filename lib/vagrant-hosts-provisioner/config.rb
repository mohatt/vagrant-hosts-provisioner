module VagrantPlugins
  module HostsProvisioner
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :id
      attr_accessor :hostname
      attr_accessor :manage_guest
      attr_accessor :manage_host
      attr_accessor :aliases
      attr_accessor :files

      def initialize
        @id                 = UNSET_VALUE
        @hostname           = UNSET_VALUE
        @manage_guest       = UNSET_VALUE
        @manage_host        = UNSET_VALUE
        @aliases            = UNSET_VALUE
        @files              = UNSET_VALUE
      end

      def finalize!
        @id                 = 0 if @id == UNSET_VALUE
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

        errors << validate_number('id', id)
        errors << validate_bool_or_string('hostname', hostname)
        errors << validate_bool('manage_guest', manage_guest)
        errors << validate_bool('manage_host', manage_host)
        errors << validate_array_or_string('files', files)
        errors << validate_array_or_string('aliases', aliases)
        errors.compact!

        { "HostsProvisioner configuration" => errors }
      end

      # Checks if a option is Boolean
      def validate_bool(key, value)
        if ![TrueClass, FalseClass].include?(value.class) && value != UNSET_VALUE
          I18n.t('vagrant_hostsprovisioner.error.invalid_bool', {
            :config_key    => key,
            :invalid_class => value.class.to_s
          })
        else
          nil
        end
      end

      # Checks if a option is a Number
      def validate_number(key, value)
        if !value.kind_of?(Fixnum) && !value.kind_of?(NilClass)
          I18n.t('vagrant_hostsprovisioner.error.not_a_number', {
            :config_key    => key,
            :invalid_class => value.class.to_s
          })
        else
          nil
        end
      end

      # Checks if a option is an Array or String
      def validate_array_or_string(key, value)
        if !value.kind_of?(Array) && !value.kind_of?(String) && !value.kind_of?(NilClass)
          I18n.t('vagrant_hostsprovisioner.error.not_an_array_or_string', {
            :config_key    => key,
            :invalid_class => value.class.to_s
          })
        else
          nil
        end
      end

      # Checks if a option is a String or Boolean
      def validate_bool_or_string(key, value)
        if ![TrueClass, FalseClass].include?(value.class) && !value.kind_of?(String) && !value.kind_of?(NilClass)
          I18n.t('vagrant_hostsprovisioner.error.not_a_bool_or_string', {
            :config_key    => key,
            :invalid_class => value.class.to_s
          })
        else
          nil
        end
      end

      # Checks if a option is a String
      def validate_string(key, value)
        if !value.kind_of?(String) && !value.kind_of?(NilClass)
          I18n.t('vagrant_hostsprovisioner.error.not_a_string', {
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
