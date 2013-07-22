if $DEBUGLIST.include?("require")
  module Kernel
    alias_method :require_debug, :require

    def require(path)
      result = require_debug(path)
      origin = caller[1]
      if origin =~ /rubygems\/custom_require/
        origin = caller[3]
      end
      puts "require(\"#{path}\")" if result
      #puts "require(\"#{path}\") => #{result} (from: #{origin})"
      #puts caller.map { |c| " => #{c}" }.join("\n")
    end

    alias_method :load_debug, :load

    def load(path)
      puts "load(\"#{path}\")"
      return load_debug(path)
    end
  end
end
