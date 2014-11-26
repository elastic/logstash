# encoding: utf-8

inputs  = ['stdin']
outputs = ['stdout']
filters = ['clone', 'json', 'grok', 'syslog_pri', 'date', 'mutate']

`rake bootstrap`

puts "installing plugins"

inputs.each do |input|
  `./bin/logstash plugin install logstash-input-#{input}`
end

outputs.each do |output|
  `./bin/logstash plugin install logstash-output-#{output}`
end

filters.each do |filter|
  `./bin/logstash plugin install logstash-filter-#{filter}`
end

puts "done!"
