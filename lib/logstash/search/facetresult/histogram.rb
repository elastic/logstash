
require "json"
require "logstash/search/facetresult/entry"

class LogStash::Search::FacetResult::Histogram < LogStash::Search::FacetResult::Entry
  # The name or key for this result.
  attr_accessor :key
  attr_accessor :mean
  attr_accessor :total
  attr_accessor :count

  # sometimes a parent call to to_json calls us with args?
  def to_json(*args)
    return {
      "key" => @key,
      "mean" => @mean,
      "total" => @total,
      "count" => @count,
    }.to_json
  end
end
