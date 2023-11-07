# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'test_helper'
require "filters/geoip/database_manager"

describe LogStash::Filters::Geoip do
  describe 'DatabaseManager', :aggregate_failures do
    let(:pipeline_id) { SecureRandom.hex(16) }
    let(:mock_geoip_plugin) do
      double("LogStash::Filters::Geoip").tap do |c|
        allow(c).to receive(:execution_context).and_return(double("EC", pipeline_id: pipeline_id))
        allow(c).to receive(:update_filter).with(anything)
      end
    end

    let(:eula_database_infos) { Hash.new { LogStash::GeoipDatabaseManagement::DbInfo::PENDING } }
    let(:eula_manager_enabled) { true }
    let(:mock_eula_manager) do
      double('LogStash::GeoipDatabaseManagement::Manager').tap do |c|
        allow(c).to receive(:enabled?).and_return(eula_manager_enabled)
        allow(c).to receive(:supported_database_types).and_return(%w(City ASN))
        allow(c).to receive(:subscribe_database_path) do |type|
          LogStash::GeoipDatabaseManagement::Subscription.new(eula_database_infos[type])
        end
      end
    end

    let(:testable_described_class) do
      Class.new(LogStash::Filters::Geoip::DatabaseManager) do
        public :eula_subscription
        public :eula_subscribed?
        public :subscribed_plugins_count
      end
    end

    subject(:db_manager) { testable_described_class.instance }

    let(:mock_logger) { double("Logger").as_null_object }

    before(:each) do
      allow(db_manager).to receive(:logger).and_return(mock_logger)
      allow(db_manager).to receive(:eula_manager).and_return(mock_eula_manager)
      allow(mock_geoip_plugin).to receive(:update_filter)
    end

    self::CITY = LogStash::GeoipDatabaseManagement::Constants::CITY
    self::ASN = LogStash::GeoipDatabaseManagement::Constants::ASN

    shared_examples "not subscribed to the EULA manager" do
      it "is not subscribed to the EULA manager" do
        expect(db_manager).to_not be_eula_subscribed
      end
    end

    shared_examples "subscribed to the EULA manager" do
      it "is subscribed to the EULA manager" do
        expect(db_manager).to be_eula_subscribed
      end
    end

    context "initialize" do
      include_examples "not subscribed to the EULA manager"
    end

    context "subscribe database path" do
      let(:eula_database_infos) {
        super().merge("City" => LogStash::GeoipDatabaseManagement::DbInfo.new(path: default_city_db_path))
      }

      shared_examples "explicit path" do
        context "when user subscribes to explicit path" do
          let(:explicit_path) { "/this/that/another.mmdb" }
          subject!(:resolved_path) { db_manager.subscribe_database_path("City", explicit_path, mock_geoip_plugin) }

          it "returns user input path" do
            expect(resolved_path).to eq(explicit_path)
          end

          it "logs about the path being configured manually" do
            expect(db_manager.logger).to have_received(:info).with(a_string_including "GeoIP database path is configured manually")
          end

          include_examples "not subscribed to the EULA manager"
        end
      end

      shared_examples "CC-fallback" do |type|
        it 'returns the CC-licensed database' do
          expect(resolved_path).to end_with("/CC/GeoLite2-#{type}.mmdb")
          expect(::File).to exist(resolved_path)
        end
        it 'logged about preparing CC' do
          expect(db_manager.logger).to have_received(:info).with(a_string_including "CC-licensed GeoIP databases are prepared")
        end
      end

      context "when manager is disabled" do
        let(:eula_manager_enabled) { false }

        include_examples "explicit path"

        context "when user does not specify an explict path" do
          subject!(:resolved_path) { db_manager.subscribe_database_path("City", nil, mock_geoip_plugin) }

          include_examples "CC-fallback", "City"
          include_examples "not subscribed to the EULA manager"
        end
      end

      context "when manager is enabled" do
        let(:eula_manager_enabled) { true }

        include_examples "explicit path"

        context "when user does not specify an explicit path" do
          subject!(:resolved_path) { db_manager.subscribe_database_path("City", nil, mock_geoip_plugin) }

          shared_examples "subscribed to expire notifications" do
            context "when the manager expires the db" do
              it "notifies the plugin" do
                db_manager.eula_subscription("City").notify(LogStash::GeoipDatabaseManagement::DbInfo::EXPIRED)
                expect(mock_geoip_plugin).to have_received(:update_filter).with(:expire)
              end
            end
            context "when the manager expires a different DB" do
              it 'does not notify the plugin' do
                db_manager.eula_subscription("ASN").notify(LogStash::GeoipDatabaseManagement::DbInfo::EXPIRED)
                expect(mock_geoip_plugin).to_not have_received(:update_filter)
              end
            end
          end

          shared_examples "subscribed to update notifications" do
            context "when the manager updates the db" do
              let(:updated_db_path) { "/this/that/another.mmdb" }
              it "notifies the plugin" do
                db_manager.eula_subscription("City").notify(LogStash::GeoipDatabaseManagement::DbInfo.new(path: updated_db_path))
                expect(mock_geoip_plugin).to have_received(:update_filter).with(:update, updated_db_path)
              end
            end
            context "when the manager updates a different DB" do
              let(:updated_db_path) { "/this/that/another.mmdb" }
              it 'does not notify the plugin' do
                db_manager.eula_subscription("ASN").notify(LogStash::GeoipDatabaseManagement::DbInfo.new(path: updated_db_path))
                expect(mock_geoip_plugin).to_not have_received(:update_filter)
              end
            end
          end

          shared_examples "logs implicit EULA" do
            it 'logs about the user implicitly accepting the MaxMind EULA' do
              expect(db_manager.logger).to have_received(:info).with(a_string_including "you accepted and agreed MaxMind EULA")
            end
          end

          context "and EULA database is expired" do
            let(:eula_database_infos) {
              super().merge("City" => LogStash::GeoipDatabaseManagement::DbInfo::EXPIRED)
            }
            it 'returns nil' do
              expect(resolved_path).to be_nil
            end
            it 'is subscribed for updates' do
              expect(db_manager.subscribed_plugins_count("City")).to eq(1)
            end
            include_examples "subscribed to update notifications"
            include_examples "logs implicit EULA"
          end

          context "and EULA database is pending" do
            let(:eula_database_infos) {
              super().merge("City" => LogStash::GeoipDatabaseManagement::DbInfo::PENDING)
            }
            include_examples "CC-fallback", "City"
            include_examples "subscribed to update notifications"
            include_examples "subscribed to expire notifications"
            include_examples "logs implicit EULA"
          end

          context "and EULA database has a recent database" do
            let(:managed_city_database) { "/this/that/GeoLite2-City.mmdb"}
            let(:eula_database_infos) {
              super().merge("City" => LogStash::GeoipDatabaseManagement::DbInfo.new(path: managed_city_database))
            }
            it 'returns the path to the managed database' do
              expect(resolved_path).to eq(managed_city_database)
            end
            it 'is subscribed for updates' do
              expect(db_manager.subscribed_plugins_count("City")).to eq(1)
            end
            include_examples "subscribed to update notifications"
            include_examples "subscribed to expire notifications"
            include_examples "logs implicit EULA"
          end
        end
      end
    end

    context "unsubscribe" do
      before(:each) do
        db_manager.subscribe_database_path("City", nil, mock_geoip_plugin)
        expect(db_manager.subscribed_plugins_count("City")).to eq(1)
      end

      it "removes plugin in state" do
        db_manager.unsubscribe_database_path("City", mock_geoip_plugin)
        expect(db_manager.subscribed_plugins_count("City")).to eq(0)
      end
    end

    context "shutdown" do
      it "unsubscribes gracefully" do
        db_manager.subscribe_database_path("City", default_city_db_path, mock_geoip_plugin)
        expect { db_manager.unsubscribe_database_path("City", mock_geoip_plugin) }.not_to raise_error
      end
    end
  end
end
