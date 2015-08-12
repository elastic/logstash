# encoding: utf-8
module LogStash
  class GemfileError < StandardError; end

  class Gemfile
    attr_accessor :gemset

    HEADER = \
      "# This is a Logstash generated Gemfile.\n" + \
      "# If you modify this file manually all comments and formatting will be lost.\n\n"

    # @params io [IO] any IO object that supports read, write, truncate, rewind
    def initialize(io)
      @io = io
      @gemset = nil
    end

    def load
      @gemset ||= DSL.parse(@io.read)
      backup
      self
    end

    def save
      raise(GemfileError, "a Gemfile must first be loaded") unless @gemset
      @io.truncate(0)
      @io.rewind
      @io.write(HEADER)
      @io.write(@gemset.to_s)
      @io.flush
    end

    def find(name)
      @gemset.find_gem(name)
    end

    # @param name [String] gem name
    # @param *requirements params following name use the same notation as the Gemfile gem DSL statement
    # @raise GemfileError if gem already exists in Gemfile
    def add(name, *requirements)
      @gemset.add_gem(Gem.parse(name, *requirements))
    end

    # update existing or add new
    # @param name [String] gem name
    # @param *requirements params following name use the same notation as the Gemfile gem DSL statement
    def update(name, *requirements)
      @gemset.update_gem(Gem.parse(name, *requirements))
    end

    # @return [Gem] removed gem or nil if not found
    def remove(name)
      @gemset.remove_gem(name)
    end

    def backup
      @original_backup = @gemset.copy
    end

    def restore
      @gemset = @original_backup
    end

    def restore!
      restore
      save
    end

    def locally_installed_gems
      @gemset.gems.select { |gem| gem.options.include?(:path) }
    end
  end

  class Gemset
    attr_accessor :sources, :gems, :gemspec

    def initialize
      @sources = []      # list of urls
      @gems = []         # list of Gem class
      @gems_by_name = {} # hash of name => Gem
      @gemspec = {}      # gemspec is a options hash
    end

    def to_s
      [sources_to_s, gemspec_to_s, gems_to_s].select{|s| !s.empty?}.join("\n") + "\n"
    end

    # @return [Gem] found gem or nil if not found
    def find_gem(name)
      @gems_by_name[name.downcase]
    end

    # @raise GemfileError if gem already exists
    def add_gem(_gem)
      raise(GemfileError, "duplicate gem #{_gem.name}") if find_gem(_gem.name)
      @gems << _gem
      @gems_by_name[_gem.name.downcase] = _gem
    end

    # update existing or add new
    def update_gem(_gem)
      if old = find_gem(_gem.name)
        @gems[@gems.index(old)] = _gem
      else
        @gems << _gem
      end
      @gems_by_name[_gem.name.downcase] = _gem
    end

    # @return [Gem] removed gem or nil if not found
    def remove_gem(name)
      if _gem = @gems_by_name.delete(name.downcase)
        @gems.delete_at(@gems.index(_gem))
      end
      _gem
    end

    # deep clone self
    def copy
      Marshal.load(Marshal.dump(self))
    end
    private

    def sources_to_s
      return "" if @sources.empty?
      @sources.map{|source| "source #{source.inspect}"}.join("\n")
    end

    def gems_to_s
      return "" if @gems.empty?
      @gems.map do |gem|
        requirements = gem.requirements.empty? ? nil : gem.requirements.map{|r| r.inspect}.join(", ")
        options = gem.options.empty? ? nil : gem.options.map{|k, v| "#{k.inspect} => #{v.inspect}"}.join(", ")
        "gem " + [gem.name.inspect, requirements, options].compact.join(", ")
      end.join("\n")
    end

    def gemspec_to_s
      return "" if @gemspec.empty?
      options = @gemspec.map{|k, v| "#{k.inspect} => #{v.inspect}"}.join(", ")
      "gemspec #{options}"
    end
  end

  # DSL is a minimal, incomplete Gemfile DSL subset parser, only what is currently required is implemented.
  class DSL
    attr_reader :gemset

    def initialize
      @gemset = Gemset.new
    end

    # @param gemfile_content [String] the Gemfile string content
    # @return [Gemset] parsed Gemfile content as a Gemset
    def self.parse(gemfile_content)
      dsl = self.new
      dsl.instance_eval(gemfile_content)
      dsl.gemset
    end

    # DSL methods

    def source(url)
      @gemset.sources << url
    end

    def gem(name, *requirements)
      parsed = Gem.parse(name, *requirements)
      @gemset.add_gem(parsed)
    end

    def gemspec(options = {})
      raise(GemfileError, "cannot declare multiple gemspec directives") unless @gemset.gemspec.empty?
      @gemset.gemspec = options
    end
  end

  class Gem
    attr_accessor :name, :requirements, :options

    def initialize(name, requirements = [], options = {})
      @name = name
      @requirements = requirements.map{|r| r.to_s.strip}.select{|r| !r.empty?}
      @options = options
    end

    def self.parse(name, *requirements)
      options = requirements.last.is_a?(Hash) ? requirements.pop : {}
      self.new(name, requirements, options)
    end
  end
end
