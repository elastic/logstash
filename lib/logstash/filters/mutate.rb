require "logstash/filters/base"
require "logstash/namespace"
require "logstash/time"

# The mutate filter ...
#
# This filter is not guaranteed to stay around. It is an experiment.
#
# TODO(sissel): Support regexp replacements like String#gsub ?
class LogStash::Filters::Mutate < LogStash::Filters::Base
  config_name "mutate"

  # Rename a field.
  config :rename, :validate => :hash

  # Remove a field.
  config :remove, :validate => :array

  # Replace a field with a new value.
  config :replace, :validate => :hash

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless event.type == @type or @type.nil?

    rename(event) if @rename
    remove(event) if @remove
    replace(event) if @replace

    filter_matched(event)
  end # def filter

  private
  def remove(event)
    @remove.each do |field|
      # TODO(sissel): use event.sprintf on the field names?
      event.remove(field)
    end
  end # def remove

  private
  def rename(event)
    @rename.each do |old, new|
      # TODO(sissel): use event.sprintf on the field names?
      event[new] = event[old]
      event.remove(old)
    end
  end # def remove

  private
  def replace(event)
    # TODO(sissel): use event.sprintf on the field names?
    @replace.each do |field, newvalue|
      next unless event[field]
      event[field] = event.sprintf(newvalue)
    end
  end # def replace
end # class LogStash::Filters::Date
