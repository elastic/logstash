require "logstash/inputs/imap"
require "mail"

describe LogStash::Inputs::IMAP do
  user = "logstash"
  password = "secret"
  msg_time = Time.new
  msg_text = "foo\nbar\nbaz"
  msg_html = "<p>a paragraph</p>\n\n"

  msg = Mail.new do
    from     "me@example.com"
    to       "you@example.com"
    subject  "logstash imap input test"
    date     msg_time
    body     msg_text
    add_file :filename => "some.html", :content => msg_html
  end

  context "with both text and html parts" do
    context "when no content-type selected" do
      it "should select text/plain part" do
        config = {"type" => "imap", "host" => "localhost",
                  "user" => "#{user}", "password" => "#{password}"}

        input = LogStash::Inputs::IMAP.new config
        input.register
        event = input.parse_mail(msg)
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
        event = input.parse_mail(msg)
        insist { event["message"] } == msg_html
      end
    end
  end

end
