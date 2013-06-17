require "logstash/filters/base"
require "logstash/namespace"

# Set fields from environment variables
class LogStash::Filters::Environment < LogStash::Filters::Base
  config_name "environment"
  milestone 1

  # Specify a hash of fields to the environment variable
  # A hash of matches of field => environment variable
  config :add_field_from_env, :validate => :hash, :default => {}

  public
  def register
    # Nothing
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    @add_field_from_env.each do |field, env|
      event.fields[field] = ENV[env]
    end
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Environment
