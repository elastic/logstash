
require "logstash/namespace"
require "logstash/logging"
require "logstash/event"

class LogStash::Search::Base
  # Do a search. 
  def search(query)
    raise "The class #{self.class.name} must implement the 'search' method."
  end # def search

  # Returns a histogram by field of a query.
  def histogram(query, field, interval=nil)
    raise "The class #{self.class.name} must implement the 'histogram' method."
  end

  # Returns a list of popular terms from a query
  def popular_terms(query, fields, count=10)
    raise "The class #{self.class.name} must implement the 'popular_terms' method."
  end

  # Count the results.
  # The default count method provided by LogStash::Search::Base is not likely
  # an optimal uery.
  def count(query)
    raise "The class #{self.class.name} must implement the 'count' method."
  end

end # class LogStash::Search::Base
