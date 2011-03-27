jarpath = File.join(File.dirname(__FILE__), "../../vendor/**/*.jar")
Dir[jarpath].each do |jar|
  if $DEBUG
    puts "Loading #{jar}"
  end
  require jar
end

