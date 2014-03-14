require "test_utils"
require "rumbster"
require "message_observers"

describe "outputs/email", :broken => true do
    extend LogStash::RSpec

    @@port=2525
    let (:rumbster) { Rumbster.new(@@port) }
    let (:message_observer) { MailMessageObserver.new }

    before :each do
        rumbster.add_observer message_observer
        rumbster.start
    end

    after :each do
        rumbster.stop
    end

    describe  "use a list of email as mail.to (LOGSTASH-827)" do
        config <<-CONFIG
        input {
            generator {
                message => "hello world"
                count => 1
                type => "generator"
            }
        }
        filter {
            noop {
                add_field => ["dummy_match", "ok"]
            }
        }
        output{
            email {
                to => "email1@host, email2@host"
                match => ["mymatch", "dummy_match,ok"]
                options => ["port", #{@@port}]
            }
        }
        CONFIG

        agent do
            insist {message_observer.messages.size} == 1
            insist {message_observer.messages[0].to} == ["email1@host", "email2@host"]
        end
    end

    describe  "use an array of email as mail.to (LOGSTASH-827)" do
        config <<-CONFIG
        input {
            generator {
                message => "hello world"
                count => 1
                type => "generator"
            }
        }
        filter {
            noop {
                add_field => ["dummy_match", "ok"]
                add_field => ["to_addr", "email1@host"]
                add_field => ["to_addr", "email2@host"]
            }
        }
        output{
            email {
                to => "%{to_addr}"
                match => ["mymatch", "dummy_match,ok"]
                options => ["port", #{@@port}]
            }
        }
        CONFIG

        agent do
            insist {message_observer.messages.size} == 1
            insist {message_observer.messages[0].to} == ["email1@host", "email2@host"]
        end
    end

    describe  "multi-lined text body (LOGSTASH-841)" do
        config <<-CONFIG
        input {
            generator {
                message => "hello world"
                count => 1
                type => "generator"
            }
        }
        filter {
            noop {
                add_field => ["dummy_match", "ok"]
            }
        }
        output{
            email {
                to => "me@host"
                subject => "Hello World"
                body => "Line1\\nLine2\\nLine3"
                match => ["mymatch", "dummy_match,*"]
                options => ["port", #{@@port}]
            }
        }
        CONFIG

        agent do
            insist {message_observer.messages.size} == 1
            insist {message_observer.messages[0].subject} == "Hello World"
            insist {message_observer.messages[0].body.raw_source} == "Line1\r\nLine2\r\nLine3"
        end
    end

    describe  "use nil authenticationType (LOGSTASH-559)" do
        config <<-CONFIG
        input {
            generator {
                message => "hello world"
                count => 1
                type => "generator"
            }
        }
        filter {
            noop {
                add_field => ["dummy_match", "ok"]
            }
        }
        output{
            email {
                to => "me@host"
                subject => "Hello World"
                body => "Line1\\nLine2\\nLine3"
                match => ["mymatch", "dummy_match,*"]
                options => ["port", #{@@port}, "authenticationType", "nil"]
            }
        }
        CONFIG

        agent do
            insist {message_observer.messages.size} == 1
            insist {message_observer.messages[0].subject} == "Hello World"
            insist {message_observer.messages[0].body.raw_source} == "Line1\r\nLine2\r\nLine3"
        end
    end

    describe  "match on source and message (LOGSTASH-826)" do
        config <<-CONFIG
        input {
            generator {
                message => "hello world"
                count => 1
                type => "generator"
            }
        }
        output{
            email {
                to => "me@host"
                subject => "Hello World"
                body => "Mail body"
                match => ["messageAndSourceMatch", "message,*hello,,and,source,*generator"]
                options => ["port", #{@@port}, "authenticationType", "nil"]
            }
        }
        CONFIG

        agent do
            insist {message_observer.messages.size} == 1
            insist {message_observer.messages[0].subject} == "Hello World"
            insist {message_observer.messages[0].body.raw_source} == "Mail body"
        end
    end
end


