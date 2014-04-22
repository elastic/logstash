# encoding: utf-8

require "logstash/inputs/imap"
require "mail"

describe LogStash::Inputs::IMAP do
  user = "logstash"
  password = "secret"
  msg_time = Time.new
  msg_text = "foo\nbar\nbaz"
  msg_html = "<p>a paragraph</p>\n\n"

  subject do
    Mail.new do
      from     "me@example.com"
      to       "you@example.com"
      subject  "logstash imap input test"
      date     msg_time
      body     msg_text
      add_file :filename => "some.html", :content => msg_html
    end
  end

  context "with both text and html parts" do
    context "when no content-type selected" do
      it "should select text/plain part" do
        config = {"type" => "imap", "host" => "localhost",
                  "user" => "#{user}", "password" => "#{password}"}

        input = LogStash::Inputs::IMAP.new config
        input.register
        event = input.parse_mail(subject)
        insist { event["message"] } == msg_text
      end
    end

    context "when text/html content-type selected" do
      it "should select text/html part" do
        config = {"type" => "imap", "host" => "localhost",
                  "user" => "#{user}", "password" => "#{password}",
                  "content_type" => "text/html"}

        input = LogStash::Inputs::IMAP.new config
        input.register
        event = input.parse_mail(subject)
        insist { event["message"] } == msg_html
      end
    end
  end

  context "when subject is in RFC 2047 encoded-word format" do
    it "should be decoded" do
      subject.subject = "=?iso-8859-1?Q?foo_:_bar?="
      config = {"type" => "imap", "host" => "localhost",
                "user" => "#{user}", "password" => "#{password}"}

      input = LogStash::Inputs::IMAP.new config
      input.register
      event = input.parse_mail(subject)
      insist { event["subject"] } == "foo : bar"
    end
  end

  context "with multiple values for same header" do
    it "should add 2 values as array in event" do
      subject.received = "test1"
      subject.received = "test2"

      config = {"type" => "imap", "host" => "localhost",
                "user" => "#{user}", "password" => "#{password}"}

      input = LogStash::Inputs::IMAP.new config
      input.register
      event = input.parse_mail(subject)
      insist { event["received"] } == ["test1", "test2"]
    end

    it "should add more than 2 values as array in event" do
      subject.received = "test1"
      subject.received = "test2"
      subject.received = "test3"

      config = {"type" => "imap", "host" => "localhost",
                "user" => "#{user}", "password" => "#{password}"}

      input = LogStash::Inputs::IMAP.new config
      input.register
      event = input.parse_mail(subject)
      insist { event["received"] } == ["test1", "test2", "test3"]
    end
  end
end
