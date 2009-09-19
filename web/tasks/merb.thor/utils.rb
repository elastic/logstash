class String
  def /(other)
    (Pathname.new(self) + other).to_s
  end
end

module ColorfulMessages
  
  # red
  def error(*messages)
    puts messages.map { |msg| "\033[1;31m#{msg}\033[0m" }
  end
  
  # yellow
  def warning(*messages)
    puts messages.map { |msg| "\033[1;33m#{msg}\033[0m" }
  end
  
  # green
  def success(*messages)
    puts messages.map { |msg| "\033[1;32m#{msg}\033[0m" }
  end
  
  alias_method :message, :success
  
  # magenta
  def note(*messages)
    puts messages.map { |msg| "\033[1;35m#{msg}\033[0m" }
  end
  
  # blue
  def info(*messages)
    puts messages.map { |msg| "\033[1;34m#{msg}\033[0m" }
  end
  
end

module ThorUI
  extend ColorfulMessages
end
