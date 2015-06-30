# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.
require_relative "default_plugins"
require "rubygems/specification"
require "bootstrap/environment"


def all_installed_gems
  ENV["GEM_HOME"] = ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
  Gem.use_paths(LogStash::Environment.logstash_gem_home)

  Gem::Specification.all = nil
  all = Gem::Specification
  Gem::Specification.reset
  all
end

def gem_license_info(x)
  license = {:name => x.name, :version => x.version.to_s, :homepage => x.homepage, :email => x.email}
  if(x.license) #ah gem has license information
    license[:license] = x.license
  else
    license_file =  Dir.glob(File.join(x.gem_dir,'LICENSE*')).first #see if there is a license file
    if(license_file)
      license[:license] = File.read(license_file)
    else
      license = license.merge({:license=> 'unknown', :gem_dir => x.gem_dir, :gem_path => x.files.join("\n")})
    end
  end
  license
end

def generate_license_information
  licenses = []
  all_installed_gems.select {|y| y.gem_dir.include?('vendor') }.each do |x|
    licenses.push(gem_license_info(x))
  end
  puts YAML.dump(licenses.sort{|u, v| u[:name] <=> v[:name] })
end

