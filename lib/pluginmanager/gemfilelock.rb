# encoding: utf-8
module LogStash
  class GemfileLock

    HEADERS = [ "PATH", "GEM", "DEPENDENCIES" ]

    attr_reader :lock_file, :dependency_graph

    def initialize(lock_file)
      @lock_file        = lock_file
      @dependency_graph = DependencyGraph.new(lock_file)
    end

    def self.parse(file)
      lock_file = []
      File.open(file, "r") do |file|
        parsing, specs  = false, false
        section = {}
        file.each_line do |line|
          if HEADERS.include?(line.strip)
            parsing = true
            section = { type: line.strip, remote: "", specs: [] }
          elsif line == "\n"
            parsing, specs = false, false
            lock_file << section
          elsif parsing
            line = line[2..-1]
            if line.start_with?("remote:")
              remote = line.gsub("remote:","").strip
              section[:remote] << remote
            elsif line.start_with?("specs:")
              specs = true
            else
              line = line[2..-1].rstrip if section[:type] != "DEPENDENCIES"
              if !line[0..1].strip.empty?
                section[:specs] << { :gem => Gems.parse(line), :deps => [] }
              else
                # dependency
                section[:specs].last[:deps] << Gems.parse(line.strip)
              end
            end
          end
        end
        if section[:type] == "DEPENDENCIES" && !section[:specs].empty?
          lock_file << section
        end
      end
      self.new(lock_file)
    end

    def find_dependencies(plugin)
      dependency_graph.index[plugin].in.map { |e| e.from }
    end

    def has_dependencies?(plugin)
      entry = dependency_graph.index[plugin]
      !entry.nil? && !entry.in.empty?
    end

  end

  class DependencyGraph

    attr_reader :index, :dependencies

    class Node
      attr_reader :gem, :edges

      def initialize(gem)
        @gem       = gem
        @edges = []
      end

      def add_edge(edge, direction)
        @edges << { :edge => edge, :dir => direction }
      end

      def out
        @edges.select { |edge| edge[:dir] == :out }.map { |e| e[:edge] }
      end

      def in
        @edges.select { |edge| edge[:dir] == :in }.map { |e| e[:edge] }
      end

      def to_s
        "#{gem}"
      end
    end

    class Edge
      attr_reader :from, :to
      def initialize(from, to)
        @from = from
        @to   = to
      end

      def to_s
        "#{from} --> #{to}"
      end
    end

    def initialize(lock_file)
      @lock_file    = lock_file
      @dependencies = extract_dependencies(lock_file)
      @dag          = build_dag(lock_file)
    end

    def build_dag(lock_file)
      @index = Hash.new
      gems = lock_file.select { |section| section[:type] == "GEM" }.first
      gems[:specs].each do |spec|
        gem  = spec[:gem]
        next unless dependencies.include?(gem.name)
        node = fetch_or_create_node(gem.name)
        spec[:deps].each do |dep|
          next unless dependencies.include?(dep.name)
          dep_node = fetch_or_create_node(dep.name)
          node.add_edge(Edge.new(node, dep_node), :out)
          dep_node.add_edge(Edge.new(node, dep_node), :in)
        end
      end
    end

    def extract_dependencies(lock_file)
      dependencies = lock_file.select { |section| section[:type] == "DEPENDENCIES" }.first
      dependencies[:specs].map do |spec|
        spec[:gem].name
      end
    end

    private

    def fetch_or_create_node(name)
      return index[name] if index[name]
      index[name] = Node.new(name)
      index[name]
    end

  end

  class Gems

    attr_reader :name, :requirements

    def initialize(name, requirements=[])
      @name = name
      @requirements = requirements
    end

    def self.parse(definition)
      parts = definition.split(" ")
      name  = parts[0]
      requirements = parts[1..-1].join(' ').gsub(/\(|\)/,"").split(",")
      self.new(name, requirements)
    end

    def to_s
      "#{@name} #{@requirements}"
    end

  end

end
