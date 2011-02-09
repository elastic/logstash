require "logstash/namespace"
require "logstash/logging"

class LogStash::Search::Query
  # The query string
  attr_accessor :query_string

  # The offset to start at (like SQL's SELECT ... OFFSET n)
  attr_accessor :offset

  # The max number of results to return. (like SQL's SELECT ... LIMIT n)
  attr_accessor :count

  # New query object.
  #
  # 'settings' should be a hash containing:
  # 
  # * :query_string - a string query for searching
  # * :offset - (optional, default 0) offset to search from
  # * :count - (optional, default 50) max number of results to return
  def initialize(settings)
    @query_string = settings[:query_string]
    @offset = settings[:offset] || 0
    @count = settings[:count] || 50
  end

  # Class method. Parses a query string and returns
  # a LogStash::Search::Query instance
  def self.parse(query_string)
    # TODO(sissel): I would prefer not to invent my own query language.
    # Can we be similar to Lucene, SQL, or other query languages?
    return self.new(:query_string => query_string)
  end

end # class LogStash::Search::Query
