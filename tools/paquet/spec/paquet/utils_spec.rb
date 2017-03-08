# encoding: utf-8
require "paquet/utils"
require "stud/temporary"
require "spec_helper"

describe Paquet::Utils do
  subject { described_class }

  let(:url) { "https://localhost:8898/my-file.txt"}
  let(:destination) do
    p = Stud::Temporary.pathname
    FileUtils.mkdir_p(p)
    File.join(p, "tmp-file")
  end

  let(:content) { "its halloween, halloween!" }

  context "when the file exist" do
    before do
      stub_request(:get, url).to_return(
        { :status => 200,
          :body => content,
          :headers => {}}
      )
    end

    it "download the file to local temporary file" do
      expect(File.read(subject.download_file(url, destination))).to match(content)
    end

    context "when an exception occur" do
      let(:temporary_path) { Stud::Temporary.pathname }

      before do
        expect(URI).to receive(:parse).with(anything).and_raise("something went wrong")
      end

      it "deletes the temporary file" do
        subject.download_file(url, destination) rescue nil
        expect(File.exist?(destination)).to be_falsey
      end
    end
  end

  context "on redirection" do
    let(:redirect_response) { instance_double("Net::HTTP::Response", :code => "302", :headers => { "location" => "https://localhost:8888/new_path" }) }
    let(:response_ok) { instance_double("Net::HTTP::Response", :code => "200") }

    context "less than the maximum of redirection" do
      let(:redirect_url) { "https://localhost:8898/redirect/my-file.txt"}

      before do
        stub_request(:get, url).to_return(
          { :status => 302, :headers => { "location" => redirect_url }}
        )

        stub_request(:get, url).to_return(
          { :status => 200, :body => content }
        )
      end

      it "follows the redirection" do
        expect(File.read(subject.download_file(url, destination))).to match(content)
      end
    end

    context "too many redirection" do
      before do
        stub_request(:get, url).to_return(
          { :status => 302, :headers => { "location" => url }}
        )
      end

      it "raises an exception" do
        expect { subject.download_file(url, destination) }.to raise_error(/Too many redirection/)
      end
    end
  end

  [404, 400, 401, 500].each do |code|
    context "When the server return #{code}" do
      before do
        stub_request(:get, url).to_return(
          { :status => code }
        )
      end

      it "raises an exception" do
        expect { subject.download_file(url, destination) }.to raise_error(/Response not handled/)
      end
    end
  end
end
