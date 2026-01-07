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

require "spec_helper"
require "logstash/lsp/dispatcher"

describe LogStash::Lsp::Dispatcher do
  subject(:dispatcher) { described_class.new }

  describe "#handle" do
    context "with valid JSON-RPC request" do
      before do
        dispatcher.register("test/method") { |params| { "result" => params["value"] } }
      end

      it "dispatches to registered handler" do
        request = {
          "jsonrpc" => "2.0",
          "id" => 1,
          "method" => "test/method",
          "params" => { "value" => 42 }
        }
        response = dispatcher.handle(request)

        expect(response["jsonrpc"]).to eq("2.0")
        expect(response["id"]).to eq(1)
        expect(response["result"]).to eq({ "result" => 42 })
      end

      it "handles requests without params" do
        dispatcher.register("no/params") { |params| "ok" }
        request = {
          "jsonrpc" => "2.0",
          "id" => 2,
          "method" => "no/params"
        }
        response = dispatcher.handle(request)

        expect(response["result"]).to eq("ok")
      end
    end

    context "with notification (no id)" do
      before do
        dispatcher.register("test/notification") { |params| "ignored" }
      end

      it "returns nil for notifications" do
        request = {
          "jsonrpc" => "2.0",
          "method" => "test/notification",
          "params" => {}
        }
        response = dispatcher.handle(request)

        expect(response).to be_nil
      end
    end

    context "with unknown method" do
      it "returns method not found error" do
        request = {
          "jsonrpc" => "2.0",
          "id" => 1,
          "method" => "unknown/method"
        }
        response = dispatcher.handle(request)

        expect(response["error"]["code"]).to eq(-32601)
        expect(response["error"]["message"]).to include("Method not found")
      end

      it "ignores unknown notification methods" do
        request = {
          "jsonrpc" => "2.0",
          "method" => "unknown/notification"
        }
        response = dispatcher.handle(request)

        expect(response).to be_nil
      end
    end

    context "with invalid request" do
      it "returns invalid request error for missing jsonrpc" do
        response = dispatcher.handle({ "method" => "test" })
        expect(response["error"]["code"]).to eq(-32600)
      end

      it "returns invalid request error for missing method" do
        response = dispatcher.handle({ "jsonrpc" => "2.0", "id" => 1 })
        expect(response["error"]["code"]).to eq(-32600)
      end

      it "returns invalid request error for non-hash input" do
        response = dispatcher.handle("not a hash")
        expect(response["error"]["code"]).to eq(-32600)
      end
    end

    context "when handler raises an error" do
      before do
        dispatcher.register("error/method") { |params| raise ArgumentError, "bad param" }
        dispatcher.register("internal/error") { |params| raise "unexpected" }
      end

      it "returns invalid params error for ArgumentError" do
        request = { "jsonrpc" => "2.0", "id" => 1, "method" => "error/method" }
        response = dispatcher.handle(request)

        expect(response["error"]["code"]).to eq(-32602)
        expect(response["error"]["message"]).to eq("bad param")
      end

      it "returns internal error for other exceptions" do
        request = { "jsonrpc" => "2.0", "id" => 1, "method" => "internal/error" }
        response = dispatcher.handle(request)

        expect(response["error"]["code"]).to eq(-32603)
      end
    end
  end

  describe "document management" do
    it "tracks open documents" do
      dispatcher.open_document("file:///test.conf", "input { }", 1)
      doc = dispatcher.get_document("file:///test.conf")

      expect(doc[:content]).to eq("input { }")
      expect(doc[:version]).to eq(1)
    end

    it "updates document content" do
      dispatcher.open_document("file:///test.conf", "input { }", 1)
      dispatcher.update_document("file:///test.conf", "output { }", 2)
      doc = dispatcher.get_document("file:///test.conf")

      expect(doc[:content]).to eq("output { }")
      expect(doc[:version]).to eq(2)
    end

    it "closes documents" do
      dispatcher.open_document("file:///test.conf", "input { }", 1)
      dispatcher.close_document("file:///test.conf")

      expect(dispatcher.get_document("file:///test.conf")).to be_nil
    end
  end

  describe "initialization state" do
    it "starts uninitialized" do
      expect(dispatcher.initialized?).to be false
    end

    it "can be marked as initialized" do
      dispatcher.mark_initialized
      expect(dispatcher.initialized?).to be true
    end
  end
end
