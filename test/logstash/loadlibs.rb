jarpath = File.join(File.dirname(__FILE__), "../../vendor/**/*.jar")
Dir[jarpath].each do |jar|
  puts "Loading #{jar}"
  require jar
end

