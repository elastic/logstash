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

require "json"
require "logstash/lsp/dispatcher"
require "logstash/lsp/schema_provider"
require "logstash/lsp/document_manager"
require "logstash/lsp/completion_provider"
require "logstash/lsp/hover_provider"
require "logstash/lsp/diagnostics_provider"
require "logstash/lsp/document_symbols_provider"
require "logstash/lsp/folding_range_provider"
require "logstash/lsp/formatting_provider"
require "logstash/lsp/references_provider"
require "logstash/lsp/code_action_provider"
require "logstash/lsp/signature_help_provider"
require "logstash/lsp/inlay_hints_provider"
require "logstash/lsp/semantic_tokens_provider"

module LogStash
  module Lsp
    # Stdio-based LSP server for Language Server Protocol
    # Communicates via stdin/stdout using JSON-RPC with Content-Length headers
    class StdioServer
      CONTENT_LENGTH_HEADER = "Content-Length"
      HEADER_DELIMITER = "\r\n\r\n"

      def initialize
        @running = false
        @input = $stdin
        @output = $stdout
        @log = $stderr

        # Set binary mode for proper handling
        @input.binmode
        @output.binmode

        # Initialize LSP providers
        @document_manager = DocumentManager.new
        @schema_provider = SchemaProvider.new
        @completion_provider = CompletionProvider.new(@schema_provider, @document_manager)
        @hover_provider = HoverProvider.new(@schema_provider, @document_manager)
        @diagnostics_provider = DiagnosticsProvider.new(@schema_provider, @document_manager)
        @document_symbols_provider = DocumentSymbolsProvider.new(@schema_provider, @document_manager)
        @folding_range_provider = FoldingRangeProvider.new(@document_manager)
        @formatting_provider = FormattingProvider.new(@document_manager)
        @references_provider = ReferencesProvider.new(@document_manager)
        @code_action_provider = CodeActionProvider.new(@schema_provider, @document_manager, @diagnostics_provider)
        @signature_help_provider = SignatureHelpProvider.new(@schema_provider, @document_manager)
        @inlay_hints_provider = InlayHintsProvider.new(@schema_provider, @document_manager)
        @semantic_tokens_provider = SemanticTokensProvider.new(@schema_provider, @document_manager)

        @dispatcher = create_dispatcher
      end

      def run
        @running = true
        log("Logstash LSP server started")

        while @running
          message = read_message
          break if message.nil?

          begin
            request = JSON.parse(message)
            log("Request: #{request['method']} id=#{request['id']}")

            response = @dispatcher.handle(request)

            if response
              write_message(JSON.generate(response))
            end
          rescue JSON::ParserError => e
            error_response = {
              "jsonrpc" => "2.0",
              "id" => nil,
              "error" => { "code" => -32700, "message" => "Parse error: #{e.message}" }
            }
            write_message(JSON.generate(error_response))
          rescue => e
            log("Error handling message: #{e.message}")
            log(e.backtrace.first(5).join("\n"))
          end
        end

        log("Logstash LSP server stopped")
      end

      def stop
        @running = false
      end

      private

      def log(message)
        @log.puts("[LSP] #{message}")
        @log.flush
      end

      def create_dispatcher
        dispatcher = Dispatcher.new

        # Core LSP lifecycle
        dispatcher.register("initialize") { |params| handle_initialize(params) }
        dispatcher.register("initialized") { |_| nil }
        dispatcher.register("shutdown") { |_| @running = false; nil }
        dispatcher.register("exit") { |_| @running = false; nil }

        # Document sync
        dispatcher.register("textDocument/didOpen") { |params| handle_did_open(params) }
        dispatcher.register("textDocument/didChange") { |params| handle_did_change(params) }
        dispatcher.register("textDocument/didClose") { |params| handle_did_close(params) }
        dispatcher.register("textDocument/didSave") { |_| nil }

        # Language features
        dispatcher.register("textDocument/completion") { |params| handle_completion(params) }
        dispatcher.register("textDocument/hover") { |params| handle_hover(params) }
        dispatcher.register("textDocument/documentSymbol") { |params| handle_document_symbol(params) }
        dispatcher.register("textDocument/foldingRange") { |params| handle_folding_range(params) }
        dispatcher.register("textDocument/formatting") { |params| handle_formatting(params) }
        dispatcher.register("textDocument/definition") { |params| handle_definition(params) }
        dispatcher.register("textDocument/references") { |params| handle_references(params) }
        dispatcher.register("textDocument/codeAction") { |params| handle_code_action(params) }
        dispatcher.register("textDocument/signatureHelp") { |params| handle_signature_help(params) }
        dispatcher.register("textDocument/inlayHint") { |params| handle_inlay_hint(params) }
        dispatcher.register("textDocument/semanticTokens/full") { |params| handle_semantic_tokens_full(params) }

        # Workspace features
        dispatcher.register("workspace/didChangeWatchedFiles") { |_| nil }

        # Additional methods that editors might call
        dispatcher.register("$/cancelRequest") { |_| nil }
        dispatcher.register("$/setTrace") { |_| nil }

        dispatcher
      end

      def handle_initialize(params)
        log("Initializing LSP server")
        log("Schema has #{@schema_provider.plugin_names(:input).length} input plugins")
        log("Schema has #{@schema_provider.plugin_names(:filter).length} filter plugins")
        log("Schema has #{@schema_provider.plugin_names(:output).length} output plugins")

        {
          "capabilities" => {
            "textDocumentSync" => {
              "openClose" => true,
              "change" => 1,  # Full sync
              "save" => { "includeText" => false }
            },
            "completionProvider" => {
              "triggerCharacters" => ["{", " ", "=", ">"],
              "resolveProvider" => false
            },
            "hoverProvider" => true,
            "documentSymbolProvider" => true,
            "foldingRangeProvider" => true,
            "documentFormattingProvider" => true,
            "definitionProvider" => true,
            "referencesProvider" => true,
            "codeActionProvider" => {
              "codeActionKinds" => ["quickfix", "refactor", "source"]
            },
            "signatureHelpProvider" => {
              "triggerCharacters" => ["=", ">"]
            },
            "inlayHintProvider" => true,
            "semanticTokensProvider" => {
              "legend" => @semantic_tokens_provider.legend,
              "full" => true
            }
          },
          "serverInfo" => {
            "name" => "logstash-lsp",
            "version" => logstash_version
          }
        }
      end

      def handle_did_open(params)
        doc = params["textDocument"]
        uri = doc["uri"]
        @document_manager.open(uri, doc["text"], doc["version"] || 1)
        # Push diagnostics after opening
        publish_diagnostics(uri)
        nil
      end

      def handle_did_change(params)
        doc = params["textDocument"]
        uri = doc["uri"]
        changes = params["contentChanges"]
        if changes && !changes.empty?
          @document_manager.update(uri, changes.last["text"], doc["version"])
          # Push diagnostics after change
          publish_diagnostics(uri)
        end
        nil
      end

      def publish_diagnostics(uri)
        result = @diagnostics_provider.diagnose(uri)
        diagnostics = result["items"] || []

        notification = {
          "jsonrpc" => "2.0",
          "method" => "textDocument/publishDiagnostics",
          "params" => {
            "uri" => uri,
            "diagnostics" => diagnostics
          }
        }
        write_message(JSON.generate(notification))
        log("Published #{diagnostics.length} diagnostics for #{uri}")
      end

      def handle_did_close(params)
        @document_manager.close(params["textDocument"]["uri"])
        nil
      end

      def handle_completion(params)
        uri = params["textDocument"]["uri"]
        pos = params["position"]
        @completion_provider.complete(uri, pos["line"], pos["character"])
      end

      def handle_hover(params)
        uri = params["textDocument"]["uri"]
        pos = params["position"]
        @hover_provider.hover(uri, pos["line"], pos["character"])
      end

      def handle_document_symbol(params)
        uri = params["textDocument"]["uri"]
        @document_symbols_provider.document_symbols(uri)
      end

      def handle_folding_range(params)
        uri = params["textDocument"]["uri"]
        @folding_range_provider.folding_ranges(uri)
      end

      def handle_formatting(params)
        uri = params["textDocument"]["uri"]
        options = params["options"] || {}
        @formatting_provider.format(uri, options)
      end

      def handle_definition(params)
        uri = params["textDocument"]["uri"]
        pos = params["position"]
        @references_provider.definition(uri, pos["line"], pos["character"])
      end

      def handle_references(params)
        uri = params["textDocument"]["uri"]
        pos = params["position"]
        @references_provider.references(uri, pos["line"], pos["character"])
      end

      def handle_code_action(params)
        uri = params["textDocument"]["uri"]
        range = params["range"]
        context = params["context"] || {}
        @code_action_provider.code_actions(uri, range, context)
      end

      def handle_signature_help(params)
        uri = params["textDocument"]["uri"]
        pos = params["position"]
        @signature_help_provider.signature_help(uri, pos["line"], pos["character"])
      end

      def handle_inlay_hint(params)
        uri = params["textDocument"]["uri"]
        range = params["range"]
        @inlay_hints_provider.inlay_hints(uri, range)
      end

      def handle_semantic_tokens_full(params)
        uri = params["textDocument"]["uri"]
        @semantic_tokens_provider.full(uri)
      end

      def read_message
        # Read headers
        headers = {}
        while (line = @input.gets)
          line = line.strip
          break if line.empty?

          if line.include?(":")
            key, value = line.split(":", 2)
            headers[key.strip] = value.strip
          end
        end

        return nil if headers.empty?

        # Read body based on Content-Length
        content_length = headers[CONTENT_LENGTH_HEADER]&.to_i
        return nil unless content_length && content_length > 0

        body = @input.read(content_length)
        body
      end

      def write_message(content)
        message = "#{CONTENT_LENGTH_HEADER}: #{content.bytesize}#{HEADER_DELIMITER}#{content}"
        @output.write(message)
        @output.flush
      end

      def logstash_version
        LOGSTASH_VERSION rescue "unknown"
      end
    end
  end
end
