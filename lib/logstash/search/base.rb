
require "logstash/namespace"
require "logstash/logging"
require "logstash/plugin"
require "logstash/event"

class LogStash::Search::Base
  # Do a search. 
  #
  # This method is async. You can expect a block and therefore
  # should yield a result, not return one.
  # 
  # Implementations should yield a LogStash::Search::Result
  # LogStash::Search::Result#events must be an array of LogStash::Event
  def search(query)
    raise "The class #{self.class.name} must implement the 'search' method."
  end # def search

  # Yields a histogram by field of a query.
  #
  # This method is async. You should expect a block to be passed and therefore
  # should yield a result, not return one.
  #
  # Implementations should yield a LogStash::Search::FacetResult::Histogram
  def histogram(query, field, interval=nil)
    raise "The class #{self.class.name} must implement the 'histogram' method."
  end

  # Returns a list of popular terms from a query
  # TODO(sissel): Implement
  def popular_terms(query, fields, count=10)
    raise "The class #{self.class.name} must implement the 'popular_terms' method."
  end

  # Count the results given by a query.
  def count(query)
    raise "The class #{self.class.name} must implement the 'count' method."
  end

end # class LogStash::Search::Base
