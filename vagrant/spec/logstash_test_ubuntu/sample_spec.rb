require 'spec_helper'

describe "test" do
  describe command('ls /foo') do
    its(:stdout) { should match /No such file or directory/ }
  end
end
