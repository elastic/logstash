require "logstash/filters/base"
require "logstash/namespace"
require "logstash/version"
require "logstash/errors"

# ## This filter was replaced by a codec.
#
# See the multiline codec instead.
class LogStash::Filters::Multiline < LogStash::Filters::Base
  config_name "multiline"
  milestone 3

  # Leave these config settings until we remove this filter entirely.
  # THe idea is that we want the register method to cause an abort
  # giving the user a clue to use the codec instead of the filter.
  config :pattern, :validate => :string, :required => true
  config :source, :validate => :string, :default => "message"
  config :what, :validate => ["previous", "next"], :required => true
  config :negate, :validate => :boolean, :default => false
  config :stream_identity , :validate => :string, :default => "%{host}-%{path}-%{type}"
  config :patterns_dir, :validate => :array, :default => []

  public
  def register
    raise LogStash::ConfigurationError, "The multiline filter has been replaced by the multiline codec. Please see http://logstash.net/docs/#{LOGSTASH_VERSION}/codecs/multiline.\n"
  end # def register

  public
  def filter(event)
  end # def filter
end # class LogStash::Filters::Multiline
