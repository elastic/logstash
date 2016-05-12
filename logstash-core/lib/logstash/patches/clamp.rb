require 'clamp'
require 'logstash/environment'

module Clamp
  module Attribute
    class Instance
      def default_from_environment
        # we don't want uncontrolled var injection from the environment
        # since we're establishing that settings can be pulled from only three places:
        # 1. default settings
        # 2. yaml file
        # 3. cli arguments
      end
    end
  end

  module Option

    module StrictDeclaration

      include Clamp::Attribute::Declaration

      # Instead of letting Clamp set up accessors for the options
      # weŕe going to tightly controlling them through
      # LogStash::SETTINGS
      def define_simple_writer_for(option, &block)
        LogStash::SETTINGS.get(option.attribute_name)
        define_method(option.write_method) do |value|
          value = instance_exec(value, &block) if block
          LogStash::SETTINGS.set_value(option.attribute_name, value)
        end
      end

      def define_reader_for(option)
        define_method(option.read_method) do
          LogStash::SETTINGS.get_value(option.attribute_name)
        end
      end
    end
  end

  # Create a subclass of Clamp::Command that enforces the use of
  # LogStash::SETTINGS for setting validation
  class StrictCommand < Command
    class << self
      include ::Clamp::Option::StrictDeclaration
    end
  end
end


