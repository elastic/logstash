
require "logstash/config/string_escape"

describe LogStash::Config::StringEscape do
  let(:result) { described_class.process_escapes(text) }

  table = {
    '\\"' => '"',
    "\\'" => "'",
    "\\n" => "\n",
    "\\r" => "\r",
    "\\t" => "\t",
    "\\\\" => "\\",
  }

  table.each do |input, expected|
    context "when processing #{input.inspect}" do
      let(:text) { input }
      it "should produce #{expected.inspect}" do
        expect(result).to be == expected
      end
    end
  end
end
