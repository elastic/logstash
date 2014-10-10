require "spec_helper"
require "logstash/inputs/s3"
require "logstash/errors"
require "aws-sdk"

describe LogStash::Inputs::S3 do
  before { AWS.stub! }
  let(:day) { 3600 * 24 }
  let(:settings) {
    {
      "access_key_id" => "1234",
      "secret_access_key" => "secret",
      "bucket" => "logstash-test"
    }
  }

  describe "#list_new" do
    let(:present_object) { double(:key => 'this-should-be-present', :last_modified => Time.now) }
    let(:objects_list) {
      [
        double(:key => 'exclude-this-file-1', :last_modified => Time.now - 2 * day),
        double(:key => 'exclude/logstash', :last_modified => Time.now - 2 * day),
        present_object
      ]
    }

    it 'should allow user to exclude files from the s3 bucket' do
      AWS::S3::ObjectCollection.any_instance.stub(:with_prefix).with(nil) { objects_list }

      config = LogStash::Inputs::S3.new(settings.merge({ "exclude_pattern" => "^exclude" }))
      config.register
      config.list_new.should == [present_object.key]
    end

    it 'should support not providing a exclude pattern' do
      AWS::S3::ObjectCollection.any_instance.stub(:with_prefix).with(nil) { objects_list }

      config = LogStash::Inputs::S3.new(settings)
      config.register
      config.list_new.should == objects_list.map(&:key)
    end

    context "If the bucket is the same as the backup bucket" do
      it 'should ignore files from the bucket if they match the backup prefix' do
        objects_list = [
          double(:key => 'mybackup-log-1', :last_modified => Time.now),
          present_object
        ]

        AWS::S3::ObjectCollection.any_instance.stub(:with_prefix).with(nil) { objects_list }

        config = LogStash::Inputs::S3.new(settings.merge({ 'backup_add_prefix' => 'mybackup',
                                                           'backup_to_bucket' => settings['bucket']}))
        config.register
        config.list_new.should == [present_object.key]
      end
    end

    it 'should ignore files older than X' do
      AWS::S3::ObjectCollection.any_instance.stub(:with_prefix).with(nil) { objects_list }

      config = LogStash::Inputs::S3.new(settings.merge({ 'backup_add_prefix' => 'exclude-this-file'}))
      config.register
      config.list_new(Time.now - day).should == [present_object.key]
    end

    it 'should sort return object sorted by last_modification date with older first' do
      objects = [
        double(:key => 'YESTERDAY', :last_modified => Time.now - day),
        double(:key => 'TODAY', :last_modified => Time.now),
        double(:key => 'TWO_DAYS_AGO', :last_modified => Time.now - 2 * day)
      ]

      AWS::S3::ObjectCollection.any_instance.stub(:with_prefix).with(nil) { objects }


      config = LogStash::Inputs::S3.new(settings)
      config.register
      config.list_new.should == ['TWO_DAYS_AGO', 'YESTERDAY', 'TODAY']
    end

    describe "when doing backup on the s3" do
      it 'should copy to another s3 bucket when keeping the original file' do
        config = LogStash::Inputs::S3.new(settings.merge({ "backup_to_bucket" => "mybackup"}))
        config.register

        s3object = double()
        s3object.stub(:copy_to).with('test-file', :bucket => an_instance_of(AWS::S3::Bucket))

        config.process_backup_to_bucket(s3object, 'test-file')
      end

      it 'should move to another s3 bucket when deleting the original file' do
        config = LogStash::Inputs::S3.new(settings.merge({ "backup_to_bucket" => "mybackup", "delete" => true }))
        config.register

        s3object = double()
        s3object.stub(:move_to).with('test-file', :bucket => an_instance_of(AWS::S3::Bucket))

        config.process_backup_to_bucket(s3object, 'test-file')
      end

      it 'should add the specified prefix to the backup file' do
        config = LogStash::Inputs::S3.new(settings.merge({ "backup_to_bucket" => "mybackup",
                                                           "backup_add_prefix" => 'backup-' }))
        config.register

        s3object = double()
        s3object.stub(:copy_to).with('backup-test-file', :bucket => an_instance_of(AWS::S3::Bucket))

        config.process_backup_to_bucket(s3object, 'test-file')
      end
    end

    it 'should support doing local backup of files' do
      backup_dir = Dir.mktmpdir

      source_file = Tempfile.new('tmp-logstash-file')
      backup_file = File.join(backup_dir.to_s, Pathname.new(source_file.path).basename.to_s)

      begin
        config = LogStash::Inputs::S3.new(settings.merge({ "backup_to_dir" => backup_dir }))

        config.process_backup_to_dir(source_file)

        File.exists?(backup_file).should be_true
      ensure
        FileUtils.remove_entry_secure(backup_file, :force => true)
        FileUtils.remove_entry_secure(backup_dir)
      end
    end

    it 'should accepts a list of credentials for the aws-sdk, this is deprecated' do
      old_credentials_settings = {
        "credentials" => ['1234', 'secret'],
        "bucket" => "logstash-test"
      }

      config = LogStash::Inputs::S3.new(settings.merge({ "backup_to_dir" => "/tmp/mybackup" }))
      config.register
    end
  end
end
