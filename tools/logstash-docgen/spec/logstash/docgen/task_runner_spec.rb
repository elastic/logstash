# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "logstash/docgen/task_runner"

describe LogStash::Docgen::TaskRunner::Status do
  subject { LogStash::Docgen::TaskRunner::Status }

  context "#success?" do
    let(:name) { :making_stuff }
    let(:error) { OpenStruct.new(:message => "Something bad, OOPS!") }

    it "returns true when no errors was passed to the class" do
      expect(subject.new(name).success?).to be_truthy
    end

    it "returns false when an errors was passed to the class" do
      expect(subject.new(name, error).success?).to be_falsey
    end

    it "allows access to the name" do
      expect(subject.new(name).name).to eq(name)
    end

    it "allows access to the error" do
      expect(subject.new(name, error).error).to eq(error)
    end
  end
end

describe LogStash::Docgen::TaskRunner do
  subject { LogStash::Docgen::TaskRunner.new }
  let(:name) { :making_stuff }

  context "an execution without errors" do
    let(:job_with_no_errors) do
      lambda do
        1 + 1
      end
    end

    it "outputs the name and the status of the task" do
      output = capture do
        subject.run(name) do
          job_with_no_errors.call
        end
      end

      expect(output).to match(/#{name} > \e\[32mSUCCESS\e\[0m/)
    end

    it "returns no failures" do
      subject.run(name) do
        job_with_no_errors.call
      end

      expect(subject.failures?).to be_falsey
    end

    it "doesn't output anything to standard output" do
      subject.run(name) do
        job_with_no_errors.call
      end

      output = capture do
        subject.report_failures
      end

      expect(output).to match("")
    end
  end

  context "an execution with errors" do
    let(:job_with_with_errors) do
      lambda do
        1 / 0
      end
    end

    it "outputs the name and the status of the task" do
      output = capture do
        subject.run(name) do
          job_with_with_errors.call
        end
      end

      expect(output).to match(/#{name} > \e\[31mFAIL\e\[0m/)
    end

    it "returns failures" do
      subject.run(name) do
        job_with_with_errors.call
      end

      expect(subject.failures?).to be_truthy
    end

    it "outputs errors to standard output" do
      subject.run(name) do
        job_with_no_errors.call
      end

      subject.run(:not_working_bob) do
        job_with_no_errors.call
      end

      output = capture do
        subject.report_failures
      end

      expect(output).to match(/FAILURE: #{name}/)
      expect(output).to match(/Exception:/)

      expect(output).to match(/FAILURE: not_working_bob/)
    end
  end
end
