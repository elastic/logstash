module LogStash
  module Plugins
    module ECSCompatibilitySupport
      def self.included(base)
        base.extend(ArgumentValidator)
        base.config(:ecs_compatibility, :validate => :ecs_compatibility_argument,
                                        :attr_accessor => false)
      end

      def ecs_compatibility
        @_ecs_compatibility || LogStash::Util.synchronize(self) do
          @_ecs_compatibility ||= begin
            # use config_init-set value if present
            break @ecs_compatibility unless @ecs_compatibility.nil?

            pipeline = execution_context.pipeline
            pipeline_settings = pipeline && pipeline.settings
            pipeline_settings ||= LogStash::SETTINGS

            pipeline_settings.get_value('pipeline.ecs_compatibility').to_sym
          end
        end
      end

      module ArgumentValidator
        V_PREFIXED_INTEGER_PATTERN = %r(\Av[1-9][0-9]?\Z).freeze
        private_constant :V_PREFIXED_INTEGER_PATTERN

        def validate_value(value, validator)
          return super unless validator == :ecs_compatibility_argument

          value = deep_replace(value)
          value = hash_or_array(value)

          if value.size == 1
            return true, :disabled if value.first.to_s == 'disabled'
            return true, value.first.to_sym if value.first.to_s =~ V_PREFIXED_INTEGER_PATTERN
          end

          return false, "Expected a v-prefixed integer major-version number (e.g., `v1`) or the literal `disabled`, got #{value.inspect}"
        end
      end
    end
  end
end
