
require "logstash/search/facetresult/entry"
class LogStash::Search::FacetResult::Histogram < LogStash::Search::FacetResult::Entry
  # The name or key for this result.
  attr_accessor :key
  attr_accessor :mean
  attr_accessor :total
  attr_accessor :count
end
