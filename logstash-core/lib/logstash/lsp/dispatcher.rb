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

module LogStash
  module Lsp
    # JSON-RPC 2.0 dispatcher for Language Server Protocol
    class Dispatcher
      # JSON-RPC error codes
      PARSE_ERROR = -32700
      INVALID_REQUEST = -32600
      METHOD_NOT_FOUND = -32601
      INVALID_PARAMS = -32602
      INTERNAL_ERROR = -32603

      def initialize
        @handlers = {}
        @initialized = false
        @documents = {}  # uri => content
      end

      # Register a handler for an LSP method
      def register(method_name, &block)
        @handlers[method_name] = block
      end

      # Handle a JSON-RPC request
      def handle(request)
        # Validate JSON-RPC structure
        unless valid_request?(request)
          return error_response(nil, INVALID_REQUEST, "Invalid JSON-RPC request")
        end

        method_name = request["method"]
        params = request["params"] || {}
        id = request["id"]

        # Handle notification (no id) vs request (has id)
        is_notification = id.nil?

        # Dispatch to handler
        handler = @handlers[method_name]

        if handler.nil?
          return nil if is_notification  # Notifications with unknown methods are ignored
          return error_response(id, METHOD_NOT_FOUND, "Method not found: #{method_name}")
        end

        begin
          result = handler.call(params)
          return nil if is_notification  # Notifications don't get responses
          success_response(id, result)
        rescue ArgumentError => e
          error_response(id, INVALID_PARAMS, e.message)
        rescue => e
          error_response(id, INTERNAL_ERROR, "#{e.class}: #{e.message}")
        end
      end

      # Track document content for LSP operations
      def open_document(uri, content, version = 1)
        @documents[uri] = { content: content, version: version }
      end

      def update_document(uri, content, version)
        if @documents[uri]
          @documents[uri][:content] = content
          @documents[uri][:version] = version
        else
          open_document(uri, content, version)
        end
      end

      def close_document(uri)
        @documents.delete(uri)
      end

      def get_document(uri)
        @documents[uri]
      end

      def initialized?
        @initialized
      end

      def mark_initialized
        @initialized = true
      end

      private

      def valid_request?(request)
        return false unless request.is_a?(Hash)
        return false unless request["jsonrpc"] == "2.0"
        return false unless request["method"].is_a?(String)
        true
      end

      def success_response(id, result)
        {
          "jsonrpc" => "2.0",
          "id" => id,
          "result" => result
        }
      end

      def error_response(id, code, message, data = nil)
        response = {
          "jsonrpc" => "2.0",
          "id" => id,
          "error" => {
            "code" => code,
            "message" => message
          }
        }
        response["error"]["data"] = data if data
        response
      end
    end
  end
end
