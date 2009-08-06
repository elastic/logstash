#!/usr/bin/ruby

require 'rubygems'
require 'ferret'
require 'json'

include Ferret
include Ferret::Search

reader = Index::IndexReader.new(ARGV[0])
search = Searcher.new(reader)
qp = QueryParser.new(:fields => reader.fields,
                     :tokenized_fields => reader.tokenized_fields,
                     :or_default => false)
query = qp.parse(ARGV[1])
search.search_each(query, :limit => :all, :sort => "@DATE") do |id, score|
  puts "#{reader[id][:@SOURCE_HOST]} | #{reader[id][:@LOG_NAME]} | #{reader[id][:@LINE]}"
end
