require "csv"

#0.003,psych/nodes/mapping,/Users/jls/.rvm/rubies/jruby-1.7.8/lib/ruby/shared/psych/nodes.rb:6:in `(root)'

durations = {}
durations.default = 0

CSV.foreach(ARGV[0]) do |duration, path, source|
  source, line, where = source.split(":")
  #{"0.002"=>"/Users/jls/projects/logstash/vendor/bundle/jruby/1.9/gems/clamp-0.6.3/lib/clamp.rb"}
  if source.include?("jruby/1.9/gems")
    # Get the gem name
    source = source.gsub(/.*\/jruby\/1.9\/gems/, "")[/[^\/]+/]
  elsif source.include?("/lib/logstash/")
    source = source.gsub(/^.*(\/lib\/logstash\/)/, "/lib/logstash/")
  end
  durations[source] += duration.to_f
end

durations.sort_by { |k,v| v }.each do |k,v| 
  puts "#{v} #{k}"
end
