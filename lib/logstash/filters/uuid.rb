# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "securerandom"

# The uuid filter allows you to add a UUID field to messages.
# This is useful to be able to control the _id messages are indexed into Elasticsearch
# with, so that you can insert duplicate messages (i.e. the same message multiple times
# without creating duplicates) - for log pipeline reliability
#
class LogStash::Filters::Uuid < LogStash::Filters::Base
  config_name "uuid"
  milestone 2

  # Add a UUID to a field.
  #
  # Example:
  #
  #     filter {
  #       uuid {
  #         target => "@uuid"
  #       }
  #     }
  config :target, :validate => :string, :required => true

  # If the value in the field currently (if any) should be overridden
  # by the generated UUID. Defaults to false (i.e. if the field is
  # present, with ANY value, it won't be overridden)
  #
  # Example:
  #
  #    filter {
  #       uuid {
  #         target    => "@uuid"
  #         overwrite => true
  #       }
  #    }
  config :overwrite, :validate => :boolean, :default => false

  public
  def register
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    if overwrite
      event[target] = SecureRandom.uuid
    else
      event[target] ||= SecureRandom.uuid
    end

    filter_matched(event)
  end # def filter

end # class LogStash::Filters::Uuid

