require_relative '../spec_helper'

describe "plugin manager" do

  describe "install" do
    context "when the plugin exist" do

      let(:plugin) { "logstash-input-stdin" }

      it "does a successful installation" do
        cmd = command("logstash/bin/plugin install #{plugin}")
        expect(cmd[:exit_status]).to eq(0)
        expect(cmd[:stdout]).to match(/^Validating\s#{plugin}\nInstalling\s#{plugin}\nInstallation\ssuccessful$/)
      end
    end
  end
end
