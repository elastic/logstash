# encoding: utf-8
RSpec::Matchers.define :be_successful do
  match do |actual|
    actual.exit_status == 0
  end
end

RSpec::Matchers.define :fail_and_output do |expected_output|
  match do |actual|
    actual.exit_status == 1 && actual.stderr =~ expected_output
  end
end

RSpec::Matchers.define :run_successfully_and_output do |expected_output|
  match do |actual|
    (actual.exit_status == 0 || actual.exit_status.nil?) && actual.stdout =~ expected_output
  end
end

RSpec::Matchers.define :have_installed? do |name,*args|
  match do |actual|
    version = args.first
    actual.plugin_installed?(name, version)
  end
end

RSpec::Matchers.define :install_successfully do
  match do |cmd|
    expect(cmd).to run_successfully_and_output(/Installation successful/)
  end
end
