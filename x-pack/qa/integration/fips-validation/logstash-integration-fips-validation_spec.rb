require_relative "../spec_helper"

context "FipsValidation Integration Plugin" do
  def fips_configured_jvm?
    java.lang.System.getProperty("org.bouncycastle.fips.approved_only") == "true"
  end

  def fips_provider_jars
    jars_dir = java.lang.System.getProperty("logstash.fips.provider.jars.dir")
    skip "FIPS provider jars are not available" if jars_dir.nil? || jars_dir.empty?

    jars = Dir.glob(File.join(jars_dir, "*.jar"))
    skip "FIPS provider jars are not available in #{jars_dir}" if jars.empty?

    jars
  end

  def with_fips_provider_jars_on_logstash_classpath
    jar_dir = File.join(get_logstash_path, "logstash-core", "lib", "jars")
    copied_jars = []

    fips_provider_jars.each do |jar|
      destination = File.join(jar_dir, File.basename(jar))
      next if File.exist?(destination)

      FileUtils.cp(jar, destination)
      copied_jars << destination
    end

    yield
  ensure
    copied_jars&.each { |jar| FileUtils.rm_f(jar) }
  end

  def create_bcfks_truststore(security_dir)
    java_home = java.lang.System.getProperty("java.home")
    keytool = File.join(java_home, "bin", "keytool")
    source_truststore = File.join(java_home, "lib", "security", "cacerts")
    destination_truststore = File.join(security_dir, "cacerts.bcfks")
    provider_path = fips_provider_jars.join(File::PATH_SEPARATOR)

    command = [
      keytool,
      "-importkeystore",
      "-srckeystore", source_truststore,
      "-destkeystore", destination_truststore,
      "-srcstoretype", "jks",
      "-deststoretype", "bcfks",
      "-providerpath", provider_path,
      "-provider", "org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider",
      "-deststorepass", "changeit",
      "-srcstorepass", "changeit",
      "-noprompt"
    ]

    stdout, stderr, status = Open3.capture3(*command)
    raise "Failed to create BCFKS truststore: #{stdout}\n#{stderr}" unless status.success?

    destination_truststore
  end

  def logstash_with_standard_fips_files(cmd, options = {})
    temporary_settings = Stud::Temporary.directory
    temporary_data = Stud::Temporary.directory
    security_dir = File.join(temporary_settings, "security")
    FileUtils.mkdir_p(security_dir)

    fips_java_security = File.expand_path("fixtures/java.security", __dir__)
    FileUtils.cp(fips_java_security, File.join(security_dir, "java.security"))
    truststore = create_bcfks_truststore(security_dir)

    IO.write(
      File.join(temporary_settings, "jvm.options"),
      [
        "-Dio.netty.ssl.provider=JDK",
        "-Djava.security.properties=#{File.join(security_dir, "java.security")}",
        "-Djavax.net.ssl.trustStore=#{truststore}",
        "-Djavax.net.ssl.trustStoreType=BCFKS",
        "-Djavax.net.ssl.trustStoreProvider=BCFIPS",
        "-Djavax.net.ssl.trustStorePassword=changeit",
        "-Dssl.KeyManagerFactory.algorithm=PKIX",
        "-Dssl.TrustManagerFactory.algorithm=PKIX",
        "-Dorg.bouncycastle.fips.approved_only=true"
      ].join("\n")
    )

    settings = {
      "xpack.security.fips_mode.enabled" => true,
      "xpack.security.fips_mode.required_providers" => ["BCFIPS", "BCJSSE"]
    }.merge(options.fetch(:settings, {}))
    IO.write(File.join(temporary_settings, "logstash.yml"), YAML.dump(settings))
    FileUtils.cp(File.join(get_logstash_path, "config", "log4j2.properties"), File.join(temporary_settings, "log4j2.properties"))

    cmd = logstash_command_append(cmd, "--path.settings", temporary_settings)
    cmd = logstash_command_append(cmd, "--path.data", temporary_data)

    Belzebuth.run(cmd, { :directory => get_logstash_path }.merge(options.fetch(:belzebuth, {})))
  end

  context "when running on stock Logstash", :skip_fips do
    # on non-FIPS Logstash, we need to install the plugin ourselves
    before(:all) do
      logstash_home = Pathname.new(get_logstash_path).cleanpath
      build_dir = (logstash_home / "build" / "gems")
      gems = build_dir.glob("logstash-integration-fips_validation-*.gem")
      fail("No FipsValidation Gem in #{build_dir}") if gems.none?
      fail("Multiple FipsValidation Gems in #{build_dir}") if gems.size > 1
      fips_validation_plugin = gems.first

      response = logstash_plugin("install", fips_validation_plugin.to_s)
      aggregate_failures('setup') do
        expect(response).to be_successful
        expect(response.stdout_lines.map(&:chomp)).to include("Installation successful")
      end
    end
    after(:all) do
      response = logstash_plugin("remove", "logstash-integration-fips_validation")
      expect(response).to be_successful
    end
    it "prevents Logstash from running and logs helpful guidance" do
      process = logstash_with_empty_default("bin/logstash --log.level=debug -e 'input { generator { count => 1 } }'", timeout: 60)

      aggregate_failures do
        expect(process).to_not be_successful
        process.stdout_lines.join.tap do |stdout|
          expect(stdout).to_not include("Pipeline started")
          expect(stdout).to include("Java security providers are misconfigured")
          expect(stdout).to include("Java SecureRandom provider is misconfigured")
          expect(stdout).to include("Bouncycastle Crypto unavailable")
          expect(stdout).to include("Logstash is not configured in a FIPS-compliant manner")
        end
      end
    end
  end

  context "when running on FIPS-configured Logstash" do
    it "starts when FIPS mode is enabled and required providers are present" do
      skip "requires a FIPS-configured JVM with Bouncy Castle providers" unless fips_configured_jvm?

      process = logstash_with_empty_default(
        "bin/logstash --log.level=debug -e 'input { generator { count => 1 } } output { stdout {} }'",
        {
          :timeout => 60,
          :settings => {
            "xpack.security.fips_mode.enabled" => true,
            "xpack.security.fips_mode.required_providers" => ["BCFIPS", "BCJSSE"]
          }
        }
      )

      aggregate_failures do
        expect(process).to be_successful
        process.stdout_lines.join.tap do |stdout|
          expect(stdout).to include("Pipeline started")
          expect(stdout).not_to include("required FIPS security providers")
        end
      end
    end
  end

  context "when standard Logstash is supplied with FIPS files" do
    it "starts with FIPS mode enabled and required providers present" do
      with_fips_provider_jars_on_logstash_classpath do
        process = logstash_with_standard_fips_files(
          "bin/logstash --log.level=debug -e 'input { generator { count => 1 } } output { stdout {} }'",
          :belzebuth => { :timeout => 60 }
        )

        aggregate_failures do
          expect(process).to be_successful
          process.stdout_lines.join.tap do |stdout|
            expect(stdout).to include("Pipeline started")
            expect(stdout).not_to include("required FIPS security providers")
          end
        end
      end
    end
  end
end