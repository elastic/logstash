# encoding: utf-8
require "i18n"
require "logstash/filters/base"
require "logstash/namespace"

# The i18n filter allows you to remove special characters from
# from a field
class LogStash::Filters::I18n < LogStash::Filters::Base
  config_name "i18n"
  milestone 0

  # Replaces non-ASCII characters with an ASCII approximation, or
  # if none exists, a replacement character which defaults to “?”
  #
  # Example:
  #
  #     filter {
  #       i18n {
  #          transliterate => ["field1", "field2"]
  #       }
  #     }
  config :transliterate, :validate => :array

  public
  def register
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    transliterate(event) if @transliterate

    filter_matched(event)
  end # def filter

  private
  def transliterate(event)
    @transliterate.each do |field|
      if event[field].is_a?(Array)
        event[field].map! { |v| I18n.transliterate(v).encode('UTF-8') }
      elsif event[field].is_a?(String)
        event[field] = I18n.transliterate(event[field].encode('UTF-8'))
      else
        @logger.debug("Can't transliterate something that isn't a string",
                      :field => field, :value => event[field])
      end
    end
  end # def transliterate

end # class LogStash::Filters::I18n
