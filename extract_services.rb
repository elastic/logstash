# Extract META-INFO/services/* files from jars
#
require "optparse"

output = nil

flags = OptionParser.new do |opts|
  opts.on("-o", "--output DIR",
          "Where to write the merged META-INF/services/* files") do |dir|
    output = dir
  end
end

flags.parse!(ARGV)

ARGV.each do |jar|
  # Find any files matching /META-INF/services/* in any jar given on the
  # command line.
  # Append all file content to the output directory with the same file name
  # as is in the jar.
  glob = "file:///#{File.expand_path(jar)}!/META-INF/services/*"
  Dir.glob(glob).each do |service|
    name = File.basename(service)
    File.open(File.join(output, name), "a") do |fd|
      puts "Adding #{name} from #{File.basename(jar)}"
      fd.write(File.read(service))
    end
  end
end
