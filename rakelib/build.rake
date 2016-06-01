directory "build" do |task, args|
  mkdir_p task.name unless File.directory?(task.name)
end
directory "build/bootstrap" => "build" do |task, args|
  mkdir_p task.name unless File.directory?(task.name)
end
directory "build/gems" => "build" do |task, args|
  mkdir_p task.name unless File.directory?(task.name)
end
