shared_context 'json_structure' do
  context 'time-specific' do
    let :data do
      { 'foo' => 'bar', '@timestamp' => '2014-03-08T12:34:56+0100', '@version' => 1, 'baz' => 'bax' }
    end

    it 'should decode' do
      decoded = false
      subject.decode(data.to_json + data_suffix) do |event|
        decoded = true
      end
      decoded.should be_true, "suffix: '#{data_suffix}'"
    end

    it 'should decode an event' do
      subject.decode(data.to_json) do |event|
        expect(event).to be_a LogStash::Event
      end
    end

    it 'should return an event from data with v1-specific fields' do
      subject.decode(data.to_json) do |event|
        event['foo'].should eq(data['foo'])
        event['baz'].should eq('bax')
        event['@version'].should eq(1)
      end
    end

    it 'should decode time to ::Time to UTC' do
      subject.decode(data.to_json) do |event|
        expect(event.timestamp).to be_a(::Time)
        event.timestamp.should eq(LogStash::Time.parse_iso8601(data['@timestamp']))
        event.timestamp.gmtime.hour.should eq(11) # alias #utc
      end
    end
  end
end
