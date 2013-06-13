require "logstash/outputs/base"
require "logstash/namespace"

# This output lets you send metrics to
# DataDogHQ based on Logstash events.
class LogStash::Outputs::DatadogMetrics < LogStash::Outputs::Base

  config_name "datadog_metrics"
  plugin_status "experimental"

  # Your DatadogHQ API key. https://app.datadoghq.com/account/settings#api
  config :api_key, :validate => :string, :required => true

  # The name of the time series.
  config :metric, :validate => :string, :required => true

  # A JSON array of points. Each point is in the form:
  # [[POSIX_timestamp, numeric_value], ...]
  config :points, :validate => :array, :required => true

  # The name of the host that produced the metric.
  config :host, :validate => :string

  # Set any custom tags for this event,
  # default are the Logstash tags if any.
  config :dd_tags, :validate => :array

  # The type of the metric.
  config :metric_type, :validate => ["gauge", "counter"], :default => "gauge"

end