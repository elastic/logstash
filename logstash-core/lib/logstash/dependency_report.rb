# encoding: utf-8
Thread.abort_on_exception = true
Encoding.default_external = Encoding::UTF_8
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

require "clamp"
require "logstash/namespace"
require "rubygems"
require "jars/gemspec_artifacts"

class LogStash::DependencyReport < Clamp::Command
  option [ "--csv" ], "OUTPUT_PATH", "The path to write the dependency report in csv format.",
    :required => true, :attribute_name => :output_path

  def execute
    require "csv"
    CSV.open(output_path, "wb") do |csv|
      puts "Finding gem dependencies"
      gems.each { |d| csv << d }
      puts "Finding java/jar dependencies"
      jars.each { |d| csv << d }
    end
    nil
  end

  def gems
    Gem::Specification.collect do |gem|
      [gem.name, gem.version.to_s, gem.homepage, gem.licenses.join("|")]
    end
  end

  def jars
    jars = []
    # For any gems with jar dependencies,
    #   Look at META-INF/MANIFEST.MF for any jars in each gem
    #   Note any important details.
    Gem::Specification.select { |g| g.requirements && g.requirements.any? { |r| r =~ /^jar / } }.collect do |gem|
      # Where is the gem installed
      root = gem.full_gem_path

      Dir.glob(File.join(root, "**", "*.jar")).collect do |path|
        jar = java.util.jar.JarFile.new(path)
        manifest = jar.getManifest

        pom_entries = jar.entries.select { |t| t.getName.start_with?("META-INF/maven/") && t.getName.end_with?("/pom.properties") }

        # Some jar files have multiple maven pom.properties files. It is unclear how to know what is correct?
        # TODO(sissel): Maybe we should use all pom.properties files? None of the pom.properties/pom.xml files have license information, though.
        # TODO(sissel): In some cases, there are META-INF/COPYING and
        #   META-INF/NOTICE.txt files? Can we use these somehow? There is no
        #   common syntax for parsing these files, though...
        pom_map = if pom_entries.count == 1
          pom_in = jar.getInputStream(pom_entries.first)
          pom_content = pom_in.available.times.collect { pom_in.read }.pack("C*")
          # Split non-comment lines by `key=val` into a map { key => val }
          Hash[pom_content.split(/\r?\n/).grep(/^[^#]/).map { |line| line.split("=", 2) }]
        else
          {}
        end

        next if manifest.nil?
        # convert manifest attributes to a map w/ keys .to_s
        # without this, the attribute keys will be `Object#inspect` values
        # like #<Java::JavaUtilJar::Attributes::Name0xabcdef0>
        attributes = Hash[manifest.getMainAttributes.map { |k,v| [k.to_s, v] }]

        begin
          # Prefer the maven/pom groupId when it is available.
          artifact = pom_map.fetch("artifactId", attributes.fetch("Implementation-Title"))
          group = pom_map.fetch("groupId", attributes.fetch("Implementation-Vendor-Id"))
          jars << [
            group + ":" + artifact,
            attributes.fetch("Bundle-Version"),
            attributes.fetch("Bundle-DocURL"),
            attributes.fetch("Bundle-License"),
          ]
        rescue KeyError => e
          # The jar is missing a required manifest field, it may not have any useful manifest data.
          # Ignore it and move on.
        end
      end
    end
    jars.uniq.sort
  end
end
