Dir["/home/jls/build/elasticsearch-0.15.0//lib/*.jar"].each do |jar|
    require jar
end


jarpath = File.join(File.dirname(__FILE__), "../../vendor/**/*.jar")
Dir[jarpath].each do |jar|
    require jar
end

