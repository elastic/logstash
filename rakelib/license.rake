# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.
require_relative "default_plugins"

namespace "license" do

  desc "run core specs"
  #task "core" =>  ["test:setup"] do
  task "core" do
    require 'yaml'
    generate_license_information
  end

end

def all_installed_gems
  Gem::Specification.all = nil
  all = Gem::Specification
  Gem::Specification.reset
  all
end

def generate_license_information
  licenses = []
  all_installed_gems.select {|y| y.gem_dir.include?('vendor') }.sort {|v, u| v.name  <=> u.name }.each do |x|
    if(x.license) #ah gem has license information
      licenses.push ({:name => x.name, :version => x.version.to_s, :license => x.license, :homepage => x.homepage, :email => x.email})
    else
      license = {:name => x.name, :version => x.version.to_s, :homepage => x.homepage, :email => x.email}
      license_file =  Dir.glob(File.join(x.gem_dir,'LICENSE*')).first #see if there is a license file
      if(license_file)
        file = File.open(license_file, 'r')
        data = file.read
        file.close
        license[:license] = data
      else
        license = license.merge({:license=> 'unknown', :gem_dir => x.gem_dir, :gem_path => x.files.join("\n")})
      end
      licenses.push(license)
    end
  end
  puts YAML.dump(licenses)
end

task "license" => [ "license:core" ]
