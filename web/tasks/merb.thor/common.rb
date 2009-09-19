# This was added via Merb's bundler

require "rubygems"
require "rubygems/source_index"

module Gem
  BUNDLED_SPECS = File.join(Dir.pwd, "gems", "specifications")
  MAIN_INDEX = Gem::SourceIndex.from_gems_in(BUNDLED_SPECS)
  FALLBACK_INDEX = Gem::SourceIndex.from_installed_gems
  
  def self.source_index
    MultiSourceIndex.new
  end
  
  def self.searcher
    MultiPathSearcher.new
  end
  
  class ArbitrarySearcher < GemPathSearcher
    def initialize(source_index)
      @source_index = source_index
      super()
    end
    
    def init_gemspecs
      @source_index.map { |_, spec| spec }.sort { |a,b|
        (a.name <=> b.name).nonzero? || (b.version <=> a.version)
      }
    end
  end

  class MultiPathSearcher
    def initialize
      @main_searcher = ArbitrarySearcher.new(MAIN_INDEX)
      @fallback_searcher = ArbitrarySearcher.new(FALLBACK_INDEX)
    end
    
    def find(path)
      try = @main_searcher.find(path)
      return try if try
      @fallback_searcher.find(path)
    end
    
    def find_all(path)
      try = @main_searcher.find_all(path)
      return try unless try.empty?
      @fallback_searcher.find_all(path)
    end
  end
  
  class MultiSourceIndex
    # Used by merb.thor to confirm; not needed when MSI is in use
    def load_gems_in(*args)
    end
    
    def search(*args)
      try = MAIN_INDEX.search(*args)
      return try unless try.empty?
      FALLBACK_INDEX.search(*args)
    end
    
    def find_name(*args)
      try = MAIN_INDEX.find_name(*args)
      return try unless try.empty?
      FALLBACK_INDEX.find_name(*args)
    end
  end
end