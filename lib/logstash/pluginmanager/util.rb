require 'logstash/version'

class LogStash::PluginManager::Util

  def self.logstash_plugin?(gem)

    gem_data = case
    when gem.is_a?(Gem::Specification); gem
    when (gem =~ /\.gem$/ and File.file?(gem)); Gem::Package.new(gem).spec
    else Gem::Specification.find_by_name(gem)
    end

    gem_data.metadata['logstash_plugin'] == "true" ? gem_data : false
  end

  def self.download_gem(gem_name, gem_version = '')
 
    gem_version ||= Gem::Requirement.default
 
    dep = ::Gem::Dependency.new(gem_name, gem_version)
    specs_and_sources, errors = ::Gem::SpecFetcher.fetcher.spec_for_dependency dep
    if specs_and_sources.empty?
      return false
    end
    spec, source = specs_and_sources.max_by { |s,| s.version }
    path = source.download( spec, java.lang.System.getProperty("java.io.tmpdir"))
    path
  end

  def self.installed?(name)
    Gem::Specification.any? { |x| x.name == name }
  end

  def self.matching_specs(name)
    req = Gem::Requirement.default
    re = name ? /#{name}/i : //
    specs = Gem::Specification.find_all{|spec| spec.name =~ re && req =~ spec.version}
    specs.inject({}){|result, spec| result[spec.name_tuple] = spec; result}.values
  end

  def self.ask_yesno(prompt)
    while true
      $stderr.puts ("#{prompt} [y/n]: ")
      case $stdin.getc.downcase
        when 'Y', 'y', 'j', 'J', 'yes' #j for Germans (Ja)
          return true
        when /\A[nN]o?\Z/ #n or no
          break
      end
    end
  end

  def self.load_logstash_gemspec
    logstash_spec = Gem::Specification.new do |gem|
      gem.authors       = ["Jordan Sissel", "Pete Fritchman"]
      gem.email         = ["jls@semicomplete.com", "petef@databits.net"]
      gem.description   = %q{scalable log and event management (search, archive, pipeline)}
      gem.summary       = %q{logstash - log and event management}
      gem.homepage      = "http://logstash.net/"
      gem.license       = "Apache License (2.0)"

      gem.name          = "logstash"
      gem.version       = LOGSTASH_VERSION
    end

    Gem::Specification.add_spec logstash_spec
  end

end
