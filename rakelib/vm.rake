# we need to call exit explicity  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

namespace "test" do

  namespace "vm" do

    task "setup" do
      ENV['VAGRANT_CWD'] = File.join(File.dirname(__FILE__), "..", "vagrant")
    end

    desc "vagrant up"
    task "up" => ["setup"] do
      system("vagrant up")
    end

    desc "run test in the vagrant machines"
    task "run" => ["setup"] do
      system("vagrant ssh logstash_test_ubuntu -c '#{test_cmd}'")
    end
    desc "vagrant teardown"
    task "down" => ["setup"] do
      system("vagrant down")
    end

    def test_cmd
      "cd logstash; rake test:core"
    end
  end
end

