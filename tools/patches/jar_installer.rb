require 'jar_dependencies'
require 'uri'
module Jars
  class JarInstaller

    class Dependency

      attr_reader :path, :file, :gav, :scope, :type, :coord

      def self.new( line )
        if line.match /:jar:|:pom:/
          super
        end
      end

      def setup_type( line )
        if line.match /:pom:/
          @type = :pom
        elsif line.match /:jar:/
          @type = :jar
        end
      end
      private :setup_type

      def setup_scope( line )
        @scope =
          case line
          when /:provided:/
            :provided
          when /:test:/
            :test
          else
            :runtime
          end
      end
      private :setup_scope

      def initialize( line )
        setup_type( line )

        line.sub!( /^\s+/, '' )
        @coord = line.sub( /:[^:]+:([A-Z]:\\)?[^:]+$/, '' )
        first, second = @coord.split( /:#{type}:/ )
        group_id, artifact_id = first.split( /:/ )
        parts = group_id.split( '.' )
        parts << artifact_id
        parts << second.split( /:/ )[ -1 ]
        parts << File.basename( line.sub /.:/, '' )
        @path = File.join( parts ).strip

        setup_scope( line )

        reg = /:jar:|:pom:|:test:|:compile:|:runtime:|:provided:|:system:/
        @file = line.slice(@coord.length, line.length).sub(reg, '').strip
        @system = nil != (line =~ /:system:/)
        @gav = @coord.sub(reg, ':')
      end

      def system?
        @system
      end
    end

    def self.install_jars( write_require_file = false )
      new.install_jars( write_require_file )
    end

    def self.vendor_jars( write_require_file = false )
      new.vendor_jars( write_require_file )
    end

    def self.load_from_maven( file )
      result = []
      File.read( file ).each_line do |line|
        dep = Dependency.new( line )
        result << dep if dep
      end
      result
    end

    def self.write_require_file( require_filename )
      FileUtils.mkdir_p( File.dirname( require_filename ) )
      comment = '# this is a generated file, to avoid over-writing it just delete this comment'
      if ! File.exists?( require_filename ) || File.read( require_filename ).match( comment )
        f = File.open( require_filename, 'w' )
        f.puts comment
        f.puts "require 'jar_dependencies'"
        f.puts
        f
      end
    end

    def self.vendor_file( dir, dep )
      vendored = File.join( dir, dep.path )
      FileUtils.mkdir_p( File.dirname( vendored ) )
      FileUtils.cp( dep.file, vendored ) unless dep.system?
    end

    def self.write_dep( file, dir, dep, vendor )
      return if dep.type != :jar || dep.scope != :runtime
      if dep.system?
        file.puts( "require( '#{dep.file}' )" ) if file
      elsif dep.scope == :runtime
        vendor_file( dir, dep ) if vendor
        file.puts( "require_jar( '#{dep.gav.gsub( /:/, "', '" )}' )" ) if file
      end
    end

    def self.install_deps( deps, dir, require_filename, vendor )
      f = write_require_file( require_filename ) if require_filename
      deps.each do |dep|
        write_dep( f, dir, dep, vendor )
      end
      yield f if block_given? and f
    ensure
      f.close if f
    end

    def find_spec( allow_no_file )
      specs = Dir[ '*.gemspec' ]
      case specs.size
      when 0
        raise 'no gemspec found' unless allow_no_file
      when 1
        specs.first
      else
        raise 'more then one gemspec found. please specify a specfile' unless allow_no_file
      end
    end
    private :find_spec

    def initialize( spec = nil )
      setup( spec )
    end

    def setup( spec = nil, allow_no_file = false )
      spec ||= find_spec( allow_no_file )

      case spec
      when String
        @specfile = File.expand_path( spec )
        @basedir = File.dirname( @specfile )
        spec =  eval( File.read( spec ) )
      when Gem::Specification
        if File.exists?( spec.spec_file )
          @basedir = spec.gem_dir
          @specfile = spec.spec_file
        else
          # this happens with bundle and local gems
          # there the spec_file is "not installed" but inside
          # the gem_dir directory
          Dir.chdir( spec.gem_dir ) do
            setup( nil, true )
          end
        end
      when NilClass
      else
        raise 'spec must be either String or Gem::Specification'
      end

      @spec = spec
    rescue
      # for all those strange gemspec we skip looking for jar-dependencies
    end

    def ruby_maven_install_options=( options )
      @options = options.dup
      @options.delete( :ignore_dependencies )
    end

    def vendor_jars( write_require_file = true )
      return unless has_jars?
      # do not vendor only if set explicitly via ENV/system-properties
      do_install( Jars.to_prop( Jars::VENDOR ) != 'false', write_require_file )
    end

    def install_jars( write_require_file = true )
      return unless has_jars?
      do_install( false, write_require_file )
    end

    private

    def has_jars?
      # first look if there are any requirements in the spec
      # and then if gem depends on jar-dependencies
      # only then install the jars declared in the requirements
      ! @spec.requirements.empty? && @spec.dependencies.detect { |d| d.name == 'jar-dependencies' && d.type == :runtime }
    end

    def do_install( vendor, write_require_file )
      vendor_dir = File.join( @basedir, @spec.require_path )
      jars_file = File.join( vendor_dir, "#{@spec.name}_jars.rb" )

      # write out new jars_file it write_require_file is true or
      # check timestamps:
      # do not generate file if specfile is older then the generated file
      if ! write_require_file &&
          File.exists?( jars_file ) &&
          File.mtime( @specfile ) < File.mtime( jars_file )
        # leave jars_file as is
        jars_file = nil
      end
      self.class.install_deps( install_dependencies, vendor_dir,
                               jars_file, vendor )
    end

    def setup_arguments( deps )
      args = [ 'dependency:list', "-DoutputFile=#{deps}", '-DoutputAbsoluteArtifactFilename=true', '-DincludeTypes=jar', '-DoutputScope=true', '-f', @specfile ]

      if Jars.debug?
        args << '-X'
      elsif not Jars.verbose?
        args << '--quiet'
      end

      if Jars.maven_user_settings.nil? && (proxy = Gem.configuration[ :proxy ]).is_a?( String )
        uri = URI.parse( proxy )
        args << "-DproxySet=true"
        args << "-DproxyHost=#{uri.host}"
        args << "-DproxyPort=#{uri.port}"
      end

      if defined? JRUBY_VERSION
        args << "-Dmaven.repo.local=#{java.io.File.new( Jars.home ).absolute_path}"
      else
        args << "-Dmaven.repo.local=#{File.expand_path( Jars.home )}"
      end

      args
    end

    def lazy_load_maven
      require 'maven/ruby/maven'
    rescue LoadError
      install_ruby_maven
      require 'maven/ruby/maven'
    end

    def install_ruby_maven
      require 'rubygems/dependency_installer'
      jars = Gem.loaded_specs[ 'jar-dependencies' ]
      dep = jars.dependencies.detect { |d| d.name == 'ruby-maven' }
      req = dep.nil? ? Gem::Requirement.create( '>0' ) : dep.requirement
      inst = Gem::DependencyInstaller.new( @options || {} )
      inst.install 'ruby-maven', req
    rescue => e
      warn e.backtrace.join( "\n" ) if Jars.verbose?
      raise "there was an error installing 'ruby-maven'. please install it manually: #{e.inspect}"
    end

    def monkey_patch_gem_dependencies
      # monkey patch to NOT include gem dependencies
      require 'maven/tools/gemspec_dependencies'
      eval <<EOF
      class ::Maven::Tools::GemspecDependencies
        def runtime; []; end
        def development; []; end
      end
EOF
    end

    def install_dependencies
      lazy_load_maven

      monkey_patch_gem_dependencies

      deps = File.join( @basedir, 'deps.lst' )

      maven = Maven::Ruby::Maven.new
      maven.verbose = Jars.verbose?
      maven.exec( *setup_arguments( deps ) )

      self.class.load_from_maven( deps )
    ensure
      FileUtils.rm_f( deps ) if deps
    end
  end
end
