require 'pathname'
require 'bundler/definition'

shared_context "pluginmanager validation helpers" do

  matcher :be_installed_gem do
    match do |actual|
      common(actual)
      @gemspec_present && @gem_installed
    end

    match_when_negated do |actual|
      common(actual)
      !@gemspec_present && !@gem_installed
    end

    define_method :common do |actual|
      version_suffix = /-[0-9.]+(-java)?$/
      filename_matcher = actual.match?(version_suffix) ? actual : /^#{Regexp.escape(actual)}#{version_suffix}/

      @gems = (logstash_gemdir / "gems").glob("*-*")
      @gemspecs = (logstash_gemdir / "specifications").glob("*-*.gemspec")

      @gem_installed = @gems.find { |gem| gem.basename.to_s.match?(filename_matcher) }
      @gemspec_present = @gemspecs.find { |gemspec| gemspec.basename(".gemspec").to_s.match?(filename_matcher) }
    end

    failure_message do |actual|
      reasons = []
      reasons << "the gem dir could not be found (#{@gems})" unless @gem_installed
      reasons << "the gemspec could not be found (#{@gemspecs})" unless @gemspec_present

      "expected that #{actual} would be installed, but #{reasons.join(' and ')}"
    end
    failure_message_when_negated do |actual|
      reasons = []
      reasons << "the gem dir is present (#{@gem_installed})" if @gem_installed
      reasons << "the gemspec is present (#{@gemspec_present})" if @gemspec_present

      "expected that #{actual} would not be installed, but #{reasons.join(' and ')}"
    end
  end

  matcher :be_in_gemfile do
    match do |actual|
      common(actual)
      @dep && (@version_requirements.nil? || @version_requirements == @dep.requirement)
    end
    define_method :common do |actual|
      @definition = Bundler::Definition.build(logstash_gemfile, logstash_gemfile_lock, false)
      @dep = @definition.dependencies.find { |s| s.name == actual }
    end
    chain :with_requirements do |version_requirements|
      @version_requirements = Gem::Requirement.create(version_requirements)
    end
    chain :without_requirements do
      @version_requirements = Gem::Requirement.default
    end
    failure_message do |actual|
      if @dep.nil?
        "expected the gem to be in the gemspec, but it wasn't (#{@definition.dependencies.map(&:name)})"
      else
        "expected the `#{actual}` gem to have requirements `#{@version_requirements}`, but they were `#{@dep.requirement}`"
      end
    end
  end

  def logstash_home
    return super() if defined?(super)
    return @logstash.logstash_home if @logstash
    fail("no @logstash, so we can't get logstash_home")
  end

  def logstash_gemfile
    Pathname.new(logstash_home) / "Gemfile"
  end

  def logstash_gemfile_lock
    Pathname.new(logstash_home) / "Gemfile.lock"
  end

  def logstash_gemdir
    pathname_base = (Pathname.new(logstash_home) / "vendor" / "bundle" / "jruby")
    candidate_dirs = pathname_base.glob("[0-9]*")
    case candidate_dirs.size
    when 0 then fail("no version dir found in #{pathname_base}")
    when 1 then candidate_dirs.first
    else
      fail("multiple version dirs found in #{pathname_base} (#{candidate_dirs.map(&:basename)}")
    end
  end
end