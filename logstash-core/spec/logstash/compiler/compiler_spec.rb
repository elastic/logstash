require "spec_helper"
require "logstash/compiler"
java_import Java::OrgLogstashConfigIr::DSL

describe LogStash::Compiler do
  def j
    Java::OrgLogstashConfigIr::DSL
  end

  # Static import of these useful enums
  INPUT = Java::OrgLogstashConfigIr::PluginDefinition::Type::INPUT
  FILTER = Java::OrgLogstashConfigIr::PluginDefinition::Type::FILTER
  OUTPUT = Java::OrgLogstashConfigIr::PluginDefinition::Type::OUTPUT
  CODEC = Java::OrgLogstashConfigIr::PluginDefinition::Type::OUTPUT

  describe "compiling to Pipeline" do
    subject(:source_file) { "fake_sourcefile" }
    subject(:compiled) { described_class.compile_pipeline(source, source_file) }

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
    let(:source_file) { "fake_sourcefile" }
    subject(:compiled) { described_class.compile_imperative(source, source_file) }

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
        expect(compiled[:input].get_meta.getSourceText).to eql("generator {}")
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
    end

    context "inputs" do
      subject(:input) { compiled[:input] }

      describe "a single input" do
        let(:source) { "input { generator {} }" }

        it "should contain the single input" do
          expect(input).to ir_eql(j.iPlugin(INPUT, "generator"))
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

        it "should attach source_metadata with correct info to the statements" do
          meta = compiled_section.statements.first.meta
          expect(meta.getSourceText).to eql("aplugin { count => 1 }")
          expect(meta.getSourceLine).to eql(2)
          expect(meta.getSourceColumn).to eql(13)
          expect(meta.getSourceFile).to eql(source_file)
          expect(compiled_section.statements.first.meta)
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

        it "should contain the single input" do
          expect(filter).to ir_eql(j.iPlugin(FILTER, "grok"))
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
      end

      it_should_behave_like "complex grammar", :output
    end
  end
end
