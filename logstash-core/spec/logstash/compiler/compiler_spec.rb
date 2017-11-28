require "spec_helper"
require "logstash/compiler"
require "support/helpers"
java_import Java::OrgLogstashConfigIr::DSL

describe LogStash::Compiler do
  def j
    Java::OrgLogstashConfigIr::DSL
  end

  let(:source_protocol) { "test_proto" }

  let(:settings) { mock_settings({}) }

  # Static import of these useful enums
  INPUT = Java::OrgLogstashConfigIr::PluginDefinition::Type::INPUT
  FILTER = Java::OrgLogstashConfigIr::PluginDefinition::Type::FILTER
  OUTPUT = Java::OrgLogstashConfigIr::PluginDefinition::Type::OUTPUT
  CODEC = Java::OrgLogstashConfigIr::PluginDefinition::Type::OUTPUT

  shared_examples_for("component source_with_metadata") do
    it "should set the correct protocol" do
      expect(component.source_with_metadata.protocol).to eq(source_protocol)
    end

    it "should set the id to the source id" do
      expect(component.source_with_metadata.id).to eq(source_id)
    end
  end

  describe "compiling to Pipeline" do
    subject(:source_id) { "fake_sourcefile" }
    let(:source_with_metadata) { org.logstash.common.SourceWithMetadata.new(source_protocol, source_id, 0, 0, source) }
    subject(:compiled) { puts "PCOMP"; described_class.compile_pipeline(source_with_metadata, settings) }

    describe "compiling multiple sources" do
      let(:sources) do
        [ 
          "input { input_0 {} } filter { filter_0 {} } output { output_0 {} }",
          "input { input_1 {} } filter { filter_1 {} } output { output_1 {} }"
        ]
      end

      let(:sources_with_metadata) do
        sources.map.with_index do |source, idx|
          org.logstash.common.SourceWithMetadata.new("#{source_protocol}_#{idx}", "#{source_id}_#{idx}", 0, 0, source)
        end
      end

      subject(:pipeline) { described_class.compile_sources(sources_with_metadata, false) }

      it "should generate a hash" do
        expect(pipeline.unique_hash).to be_a(String)
      end

      it "should compile cleanly" do
        expect(pipeline).to be_a(org.logstash.config.ir.PipelineIR)
      end

      it "should provide the original source" do
        expect(pipeline.original_source).to eq(sources.join("\n"))
      end

      describe "applying protocol and id metadata" do
        it "should apply the correct source metadata to all components" do
          # TODO: seems to be a jruby regression we cannot currently call each on a stream
          pipeline.get_plugin_vertices.each do |pv|
            name_idx = pv.plugin_definition.name.split("_").last
            source_protocol_idx = pv.source_with_metadata.protocol.split("_").last
            source_id_idx = pv.source_with_metadata.id.split("_").last

            expect(name_idx).to eq(source_protocol_idx)
            expect(name_idx).to eq(source_id_idx)
          end
        end
      end
    end

    describe "complex configs" do
      shared_examples_for "compilable LSCL files" do |path|
        describe "parsing #{path}" do
          let(:source) { File.read(path) }
          
          it "should compile" do
            expect(compiled).to be_java_kind_of(Java::OrgLogstashConfigIr::Pipeline)
          end
          
          it "should have a hash" do
            expect(compiled.uniqueHash)
          end
        end
      end
      
      Dir.glob(File.join(SUPPORT_DIR, "lscl_configs", "*.conf")).each do |path|
        it_should_behave_like "compilable LSCL files", path
      end
    end
  end

  describe "compiling imperative" do
    let(:source_id) { "fake_sourcefile" }
    let(:source_with_metadata) { org.logstash.common.SourceWithMetadata.new(source_protocol, source_id, 0, 0, source) }
    subject(:compiled) { described_class.compile_imperative(source_with_metadata, settings.get_value("config.support_escapes")) }

    context "when config.support_escapes" do
      let(:parser) { LogStashCompilerLSCLGrammarParser.new }

      let(:processed_value)  { 'The computer says, "No"' }

      let(:source) { 
        %q(
          input {
            foo {
              bar => "The computer says, \"No\""
            }
          }
        )
      }

      let(:compiled_string) do
        compiled[:input].toGraph.vertices.toArray.first.getPluginDefinition.arguments["bar"]
      end

      before do
        settings.set_value("config.support_escapes", process_escape_sequences)
      end

      context "is enabled" do
        let(:process_escape_sequences) { true }

        it "should process escape sequences" do
          expect(compiled_string).to be == processed_value
        end
      end

      context "is false" do
        let(:process_escape_sequences) { false }

        it "should not process escape sequences" do
          expect(compiled_string).not_to be == processed_value
        end
      end
    end
    describe "an empty file" do
      let(:source) { "input {} output {}" }

      it "should have an empty input block" do
        expect(compiled[:input]).to ir_eql(j.noop)
      end

      it "should have an empty filter block" do
        expect(compiled[:filter]).to ir_eql(j.noop)
      end

      it "should have an empty output block" do
        expect(compiled[:output]).to ir_eql(j.noop)
      end
    end

    describe "SourceMetadata" do
      let(:source) { "input { generator {} } output { }" }

      it "should attach correct source text for components" do
        expect(compiled[:input].source_with_metadata.getText).to eql("generator {}")
      end
    end

    context "plugins" do
      subject(:c_plugin) { compiled[:input] }
      let(:source) { "input { #{plugin_source} } " }

      describe "a simple plugin" do
        let(:plugin_source) { "generator {}" }

        it "should contain the plugin" do
          expect(c_plugin).to ir_eql(j.iPlugin(INPUT, "generator"))
        end
      end

      describe "a plugin with mixed parameter types" do
        let(:plugin_source) { "generator { aarg => [1] hasharg => {foo => bar} iarg => 123 farg => 123.123 sarg => 'hello'}" }
        let(:expected_plugin_args) do
          { 
            "aarg" => [1],
            "hasharg" => {"foo" => "bar"},
            "iarg" => 123,
            "farg" => 123.123,
            "sarg" => 'hello'
          }
        end

        it "should contain the plugin" do
          expect(c_plugin).to ir_eql(j.iPlugin(INPUT, "generator", expected_plugin_args))
        end
      end

      describe "a filter plugin that repeats a Hash directive" do
        let(:source) { "input { } filter { #{plugin_source} } output { } " }
        subject(:c_plugin) { compiled[:filter] }

        let(:plugin_source) do
          %q[
              grok {
                match => { "message" => "%{WORD:word}" }
                match => { "examplefield" => "%{NUMBER:num}" }
                break_on_match => false
              }
          ]
        end

        let(:expected_plugin_args) do
          {
            "match" => {
              "message" => "%{WORD:word}",
              "examplefield" => "%{NUMBER:num}"
            },
            "break_on_match" => "false"
          }
        end

        it "should merge the contents of the individual directives" do
          expect(c_plugin).to ir_eql(j.iPlugin(FILTER, "grok", expected_plugin_args))
        end

        describe "a filter plugin that has nested Hash directives" do
          let(:source) { "input { } filter { #{plugin_source} } output { } " }
          let(:plugin_source) do
            <<-FILTER
              matryoshka {
                key => "%{host}"
                filter_options => {
                  string  => "string"
                  integer => 3
                  nested  => { # <-- This is nested hash!
                    string  => "nested-string"
                    integer => 7
                    "quoted-key-string" => "nested-quoted-key-string"
                    "quoted-key-integer" => 31
                    deep    => { # <-- This is deeper nested hash!
                      string  => "deeply-nested-string"
                      integer => 127
                      "quoted-key-string" => "deeply-nested-quoted-key-string"
                      "quoted-key-integer" => 8191
                    }
                  }
                }
                ttl => 5
              }
            FILTER
          end
          subject(:c_plugin) { compiled[:filter] }

          let(:expected_plugin_args) do
            {
                "key" => "%{host}",
                "filter_options" => {
                    "string"  => "string",
                    "integer" => 3,
                    "nested"  => { # <-- This is nested hash!
                        "string"  => "nested-string",
                        "integer" => 7,
                        "quoted-key-string" => "nested-quoted-key-string",
                        "quoted-key-integer" => 31,
                        "deep"    => { # <-- This is deeper nested hash!
                            "string"  => "deeply-nested-string",
                            "integer" => 127,
                            "quoted-key-string" => "deeply-nested-quoted-key-string",
                            "quoted-key-integer" => 8191
                        }
                    }
                },
                "ttl" => 5
            }
          end

          it "should produce a nested ::Hash object" do
            expect(c_plugin).to ir_eql(j.iPlugin(FILTER, "matryoshka", expected_plugin_args))
          end
        end
      end
    end

    context "inputs" do
      subject(:input) { compiled[:input] }

      describe "a single input" do
        let(:source) { "input { generator {} }" }

        it "should contain the single input" do
          expect(input).to ir_eql(j.iPlugin(INPUT, "generator"))
        end

        it_should_behave_like("component source_with_metadata") do
          let(:component) { input }
        end
      end

      describe "two inputs" do
        let(:source) { "input { generator { count => 1 } generator { count => 2 } } output { }" }

        it "should contain both inputs" do
          expect(input).to ir_eql(j.iComposeParallel(
                                j.iPlugin(INPUT, "generator", {"count" => 1}),
                                j.iPlugin(INPUT, "generator", {"count" => 2})
                              ))
        end
      end
    end

    shared_examples_for "complex grammar" do |section|
      let(:section_name_enum) {
        case section
        when :input
          INPUT
        when :filter
          FILTER
        when :output
          OUTPUT
        else
          raise "Unknown section"
        end
      }

      let(:section) { section }
      let (:compiled_section) { compiled[section] }

      def splugin(*args)
        j.iPlugin(section_name_enum, *args)
      end

      def compose(*statements)
        if section == :filter
          j.iComposeSequence(*statements)
        else
          j.iComposeParallel(*statements)
        end
      end
      
      describe "multiple section declarations" do
        let(:source) do
          <<-EOS
            #{section} {
              aplugin { count => 1 }
            }
            
            #{section} {
              aplugin { count => 2 }
            }
          EOS
        end
        
        
        it "should contain both section declarations, in order" do
          expect(compiled_section).to ir_eql(compose(
                                      splugin("aplugin", {"count" => 1}),
                                        splugin("aplugin", {"count" => 2})
                                      ))
                                    end
      end

      describe "two plugins" do
        let(:source) do
          # We care about line/column for this test, hence the indentation
          <<-EOS
          #{section} {
            aplugin { count => 1 }
            aplugin { count => 2 }
            }
          EOS
        end

        it "should contain both" do
          expect(compiled_section).to ir_eql(compose(
                                        splugin("aplugin", {"count" => 1}),
                                        splugin("aplugin", {"count" => 2})
                                      ))
        end

        it "should attach source_with_metadata with correct info to the statements" do
          meta = compiled_section.statements.first.source_with_metadata
          expect(meta.text).to eql("aplugin { count => 1 }")
          expect(meta.line).to eql(2)
          expect(meta.column).to eql(13)
          expect(meta.id).to eql(source_id)
          expect(compiled_section.statements.first.source_with_metadata)
          expect(compiled_section)
        end
      end

      describe "if conditions" do
        describe "conditional expressions" do
          let(:source) { "#{section} { if (#{expression}) { aplugin {} } }" }
          let(:c_expression) { compiled_section.getBooleanExpression }

          describe "logical expressions" do
            describe "simple and" do
              let(:expression) { "2 > 1 and 1 < 2" }

              it "should compile correctly" do
                expect(c_expression).to ir_eql(
                                          j.eAnd(
                                            j.eGt(j.eValue(2), j.eValue(1)),
                                            j.eLt(j.eValue(1), j.eValue(2))
                                          ))
              end
            end

            describe "'in' array" do
              let(:expression) { "'foo' in ['foo', 'bar']" }

              it "should compile correctly" do
                expect(c_expression).to ir_eql(
                                          j.eIn(
                                            j.eValue('foo'),
                                            j.eValue(['foo', 'bar'])
                                          ))
              end
            end

            describe "'not in' array" do
              let(:expression) { "'foo' not in ['foo', 'bar']" }

              it "should compile correctly" do
                expect(c_expression).to ir_eql(
                                          j.eNot(
                                            j.eIn(
                                              j.eValue('foo'),
                                              j.eValue(['foo', 'bar'])
                                            )))
              end
            end

            describe "'not'" do
              let(:expression) { "!(1 > 2)" }

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eNot(j.eGt(j.eValue(1), j.eValue(2))))
              end
            end

            describe "and or precedence" do
              let(:expression) { "2 > 1 and 1 < 2 or 3 < 2" }

              it "should compile correctly" do
                expect(c_expression).to ir_eql(
                                          j.eOr(
                                            j.eAnd(
                                              j.eGt(j.eValue(2), j.eValue(1)),
                                              j.eLt(j.eValue(1), j.eValue(2))
                                            ),
                                            j.eLt(j.eValue(3), j.eValue(2))
                                          )
                                        )
              end

              describe "multiple or" do
                let(:expression) { "2 > 1 or 1 < 2 or 3 < 2" }

                it "should compile correctly" do
                  expect(c_expression).to ir_eql(
                                            j.eOr(
                                              j.eGt(j.eValue(2), j.eValue(1)),
                                              j.eOr(
                                                j.eLt(j.eValue(1), j.eValue(2)),
                                                j.eLt(j.eValue(3), j.eValue(2))
                                              )
                                            )
                                          )
                end
              end

              describe "a complex expression" do
                let(:expression) { "1 > 2 and 3 > 4 or 6 > 7 and 8 > 9" }
                false and false or true and true

                it "should compile correctly" do
                  expect(c_expression).to ir_eql(
                                            j.eOr(
                                              j.eAnd(
                                                j.eGt(j.eValue(1), j.eValue(2)),
                                                j.eGt(j.eValue(3), j.eValue(4))
                                              ),
                                              j.eAnd(
                                                j.eGt(j.eValue(6), j.eValue(7)),
                                                j.eGt(j.eValue(8), j.eValue(9))
                                              )
                                            )
                                          )
                end
              end

              describe "a complex nested expression" do
                let(:expression) { "1 > 2 and (1 > 2 and 3 > 4 or 6 > 7 and 8 > 9) or 6 > 7 and 8 > 9" }
                false and false or true and true

                it "should compile correctly" do
                  expect(c_expression).to ir_eql(
                                            j.eOr(
                                              j.eAnd(
                                                j.eGt(j.eValue(1), j.eValue(2)),
                                                j.eOr(
                                                  j.eAnd(
                                                    j.eGt(j.eValue(1), j.eValue(2)),
                                                    j.eGt(j.eValue(3), j.eValue(4))
                                                  ),
                                                  j.eAnd(
                                                    j.eGt(j.eValue(6), j.eValue(7)),
                                                    j.eGt(j.eValue(8), j.eValue(9))
                                                  )
                                                )
                                              ),
                                              j.eAnd(
                                                j.eGt(j.eValue(6), j.eValue(7)),
                                                j.eGt(j.eValue(8), j.eValue(9))
                                              )
                                            )
                                          )
                end
              end
            end
          end

          describe "comparisons" do
            describe "field not null" do
              let(:expression) { "[foo]"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eTruthy(j.eEventValue("[foo]")))
              end
            end

            describe "'=='" do
              let(:expression) { "[foo] == 5"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eEq(j.eEventValue("[foo]"), j.eValue(5.to_java)))
              end
            end

            describe "'!='" do
              let(:expression) { "[foo] != 5"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eNeq(j.eEventValue("[foo]"), j.eValue(5.to_java)))
              end
            end

            describe "'>'" do
              let(:expression) { "[foo] > 5"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eGt(j.eEventValue("[foo]"), j.eValue(5.to_java)))
              end
            end

            describe "'<'" do
              let(:expression) { "[foo] < 5"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eLt(j.eEventValue("[foo]"), j.eValue(5.to_java)))
              end
            end

            describe "'>='" do
              let(:expression) { "[foo] >= 5"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eGte(j.eEventValue("[foo]"), j.eValue(5.to_java)))
              end
            end

            describe "'<='" do
              let(:expression) { "[foo] <= 5"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eLte(j.eEventValue("[foo]"), j.eValue(5.to_java)))
              end
            end

            describe "'=~'" do
              let(:expression) { "[foo] =~ /^abc$/"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eRegexEq(j.eEventValue("[foo]"), j.eRegex('^abc$')))
              end
              
              # Believe it or not, "\.\." is a valid regexp!
              describe "when given a quoted regexp" do
                let(:expression) { '[foo] =~ "\\.\\."' }
              
                it "should compile correctly" do
                  expect(c_expression).to ir_eql(j.eRegexEq(j.eEventValue("[foo]"), j.eRegex('\\.\\.')))
                end
              end
            end

            describe "'!~'" do
              let(:expression) { "[foo] !~ /^abc$/"}

              it "should compile correctly" do
                expect(c_expression).to ir_eql(j.eRegexNeq(j.eEventValue("[foo]"), j.eRegex('^abc$')))
              end
            end
          end
        end

        describe "only true branch" do
          let (:source) { "#{section} { if [foo] == [bar] { grok {} } }" }

          it "should compile correctly" do
            expect(compiled_section).to ir_eql(j.iIf(
                                            j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                            splugin("grok")
                                          )
                                       )
          end
        end

        describe "only false branch" do
          let (:source) { "#{section} { if [foo] == [bar] { } else { fplugin {} } }" }

          it "should compile correctly" do
            expect(compiled_section).to ir_eql(j.iIf(
                                          j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                          j.noop,
                                          splugin("fplugin"),
                                        )
                                       )
          end
        end

        describe "empty if statement" do
          let (:source) { "#{section} { if [foo] == [bar] { } }" }

          it "should compile correctly" do
            expect(compiled_section).to ir_eql(j.iIf(
                                          j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                          j.noop,
                                          j.noop
                                        )
                                       )
          end
        end

        describe "if else" do
          let (:source) { "#{section} { if [foo] == [bar] { tplugin {} } else { fplugin {} } }" }

          it "should compile correctly" do
            expect(compiled_section).to ir_eql(j.iIf(
                                          j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                          splugin("tplugin"),
                                          splugin("fplugin")
                                        )
                                       )
          end
        end

        describe "if elsif else" do
          let (:source) { "#{section} { if [foo] == [bar] { tplugin {} } else if [bar] == [baz] { eifplugin {} } else { fplugin {} } }" }

          it "should compile correctly" do
            expect(compiled_section).to ir_eql(j.iIf(
                                          j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                          splugin("tplugin"),
                                          j.iIf(
                                            j.eEq(j.eEventValue("[bar]"), j.eEventValue("[baz]")),
                                            splugin("eifplugin"),
                                            splugin("fplugin")
                                          )
                                        )
                                       )
          end
        end

        describe "if elsif elsif else" do
          let (:source) do
            <<-EOS
              #{section} {
                if [foo] == [bar] { tplugin {} }
                else if [bar] == [baz] { eifplugin {} }
                else if [baz] == [bot] { eeifplugin {} }
                else { fplugin {} }
              }
            EOS
          end

          it "should compile correctly" do
            expect(compiled_section).to ir_eql(j.iIf(
                                          j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                          splugin("tplugin"),
                                          j.iIf(
                                            j.eEq(j.eEventValue("[bar]"), j.eEventValue("[baz]")),
                                            splugin("eifplugin"),
                                            j.iIf(
                                              j.eEq(j.eEventValue("[baz]"), j.eEventValue("[bot]")),
                                              splugin("eeifplugin"),
                                              splugin("fplugin")
                                            )
                                          )
                                        )
                                       )
          end

          describe "nested ifs" do
            let (:source) do
              <<-EOS
              #{section} {
                if [foo] == [bar] {
                  if [bar] == [baz] { aplugin {} }
                } else {
                  if [bar] == [baz] { bplugin {} }
                  else if [baz] == [bot] { cplugin {} }
                  else { dplugin {} }
                }
              }
              EOS
          end

          it "should compile correctly" do
            expect(compiled_section).to ir_eql(j.iIf(
                                          j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                          j.iIf(j.eEq(j.eEventValue("[bar]"), j.eEventValue("[baz]")),
                                                   splugin("aplugin"),
                                                   j.noop
                                                  ),
                                          j.iIf(
                                            j.eEq(j.eEventValue("[bar]"), j.eEventValue("[baz]")),
                                            splugin("bplugin"),
                                            j.iIf(
                                              j.eEq(j.eEventValue("[baz]"), j.eEventValue("[bot]")),
                                              splugin("cplugin"),
                                              splugin("dplugin")
                                            )
                                          )
                                        )
                                       )
          end
          end
        end
      end
    end

    context "filters" do
      subject(:filter) { compiled[:filter] }

      describe "a single filter" do
        let(:source) { "input { } filter { grok {} } output { }" }

        it "should contain the single filter" do
          expect(filter).to ir_eql(j.iPlugin(FILTER, "grok"))
        end

        it_should_behave_like("component source_with_metadata") do
          let(:component) { filter }
        end
      end

      it_should_behave_like "complex grammar", :filter
    end

    context "outputs" do
      subject(:output) { compiled[:output] }

      describe "a single output" do
        let(:source) { "input { } output { stdout {} }" }

        it "should contain the single input" do
          expect(output).to ir_eql(j.iPlugin(OUTPUT, "stdout"))
        end

        it_should_behave_like("component source_with_metadata") do
          let(:component) { output }
        end
      end

      it_should_behave_like "complex grammar", :output
    end
  end
end
