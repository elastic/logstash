# encoding: utf-8

$: << File.join(File.dirname(__FILE__), "lib")
$: << File.join(File.dirname(__FILE__), "logstash-core/lib")

task "default" => "help"

task "help" do
  puts <<HELP
What do you want to do?

Packaging?
  `rake artifact:tar`  to build a deployable .tar.gz
  `rake artifact:rpm`  to build an rpm
  `rake artifact:deb`  to build an deb

Developing?
  `rake bootstrap`     installs any dependencies for doing Logstash development
  `rake vendor:clean`  clean vendored dependencies used for Logstash development
HELP
end
