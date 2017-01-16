require "spec_helper"
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


  describe "compiling to a PipelineRunner" do
    subject(:source_file) { "fake_sourcefile" }
    subject(:compiled) { described_class.compile(source, source_file) }

    describe "a simple config" do
      let(:source) do
        <<-EOC
          input {
            stdin {}
          }
          filter {
            mutate { add_field => {"something" => "else"} }
          }
          output {
            stdout { codec => rubydebug }
          }
        EOC
      end

      it "should run correctly" do
        #compiled.start(1)
        #puts "SLEEP"
        #sleep 100
      end
    end
  end

  describe "compiling to Pipeline" do
    subject(:source_file) { "fake_sourcefile" }
    subject(:compiled) { described_class.compile_graph(source, source_file) }

    describe "a complex config" do
      let(:source) do
        <<-EOC
input {
  	stdin { }
}

filter {
  csv {
		columns => ["date","time","borough","zip_code","latitude","longitude","location","on_street_name","cross_street_name","off_street_name","number_of_persons_injured","number_of_persons_killed","number_of_pedestrians_injured","number_of_pedestrians_killed","number_of_cyclist_injured","number_of_cyclist_killed","number_of_motorist_injured","number_of_motorist_killed","contributing_factor_vehicle_1","contributing_factor_vehicle_2","contributing_factor_vehicle_3","contributing_factor_vehicle_4","contributing_factor_vehicle_5","unique_key","vehicle_type_code_1","vehicle_type_code_2","vehicle_type_code_3","vehicle_type_code_4","vehicle_type_code_5"]
	}

# Drop the first (header) row in the file

  if ([date] == "DATE") {
    drop { }
  }

# Combine latitude and longitude into single coords field
	if [latitude] and [longitude] {
		mutate {
			add_field => {
				"coords" => "%{longitude}"
				"tmplat" => "%{latitude}"
		    }
		}
		mutate {
			merge => ["coords", "tmplat"]
		}
		mutate {
		    # Convert our new array of strings back to float
		    convert => [ "coords", "float" ]
		    # Delete our temporary latitude field
		    remove_field => [ "tmplat" ]
		}
	}

  if [on_street_name] and [cross_street_name] {
	  ruby {
		# create new intersection field that combines cross street & on street names
		code => "event.set('intersection',[event.get('on_street_name'), event.get('cross_street_name')].sort.join('--'))"
	  }
  }

  # Merge date and time into datetime
	mutate {
		add_field => {
			"datetime" => "%{date} %{time}"
			"contributing_factor_vehicle" => "%{contributing_factor_vehicle_1}"
			"vehicle_type" => "%{vehicle_type_code_1}"
		}



  # convert to integer type
		convert => ["number_of_persons_injured","integer","number_of_persons_killed","integer","number_of_pedestrians_injured","integer","number_of_pedestrians_killed","integer","number_of_cyclist_injured","integer","number_of_cyclist_killed","integer","number_of_motorist_injured","integer","number_of_motorist_killed","integer"]
		strip => ["on_street_name", "cross_street_name"]
	}

  if ![number_of_persons_killed]
  {
  	mutate {
  		add_field => {"number_of_persons_killed" => "0"}
  	}
  }

  if ![number_of_persons_injured]
  {
  	mutate {
  		add_field => {"number_of_persons_injured" => "0"}
  	}
  }


  ruby {
	# Get total number of persons impacted
	code =>  "event.set('number_persons_impacted',event.get('number_of_persons_killed') + event.get('number_of_persons_injured'))"
  }


# Combine contributing_factor_vehicle_X (X=1,2,3,4,5) fields into a single field
	if [contributing_factor_vehicle_2] and "Unspecified" != [contributing_factor_vehicle_2] and [contributing_factor_vehicle_2] not in [contributing_factor_vehicle] {
		mutate {
			merge => ["contributing_factor_vehicle", "contributing_factor_vehicle_2"]
		}
	}

	if [contributing_factor_vehicle_3] and "Unspecified" != [contributing_factor_vehicle_3] and [contributing_factor_vehicle_3] not in [contributing_factor_vehicle] {
		mutate {
			merge => ["contributing_factor_vehicle", "contributing_factor_vehicle_3"]
		}
	}

	if [contributing_factor_vehicle_4] and "Unspecified" != [contributing_factor_vehicle_4] and [contributing_factor_vehicle_4] not in [contributing_factor_vehicle] {
		mutate {
			merge => ["contributing_factor_vehicle", "contributing_factor_vehicle_4"]
		}
	}

	if [contributing_factor_vehicle_5] and "Unspecified" != [contributing_factor_vehicle_5] and [contributing_factor_vehicle_5] not in [contributing_factor_vehicle]  {
		mutate {
			merge => ["contributing_factor_vehicle", "contributing_factor_vehicle_5"]
		}
	}

 # Combine vehicle_type_code_X (X=1,2,3,4,5) fields into a single field
	if [vehicle_type_code_2] and "Unspecified" != [vehicle_type_code_2] and [vehicle_type_code_2] not in [vehicle_type] {
		mutate {
			merge => ["vehicle_type", "vehicle_type_code_2"]
		}
	}
	if [vehicle_type_code_3] and "Unspecified" != [vehicle_type_code_3] and [vehicle_type_code_3] not in [vehicle_type] {
		mutate {
			merge => ["vehicle_type", "vehicle_type_code_3"]
		}
	}
	if [vehicle_type_code_4] and "Unspecified" != [vehicle_type_code_4] and [vehicle_type_code_4] not in [vehicle_type] {
		mutate {
			merge => ["vehicle_type", "vehicle_type_code_4"]
		}
	}
	if [vehicle_type_code_5] and "Unspecified" != [vehicle_type_code_5] and [vehicle_type_code_5] not in [vehicle_type] {
		mutate {
			merge => ["vehicle_type", "vehicle_type_code_5"]
		}
	}

 # Map @timestamp (event timestamp) to datetime
	date {
		match => [ "datetime", "MM/dd/YY HH:mm", "MM/dd/YY H:mm"]
		timezone => "EST"
	}

  # Grab hour of day from time
  grok {
    match => { "time" => "%{DATA:hour_of_day}:%{GREEDYDATA}" }
    }
  mutate {
    convert => ["hour_of_day", "integer"]
    }

  # Remove extra fields
	mutate {
		remove_field => ["datetime", "contributing_factor_vehicle_1", "contributing_factor_vehicle_2", "contributing_factor_vehicle_3", "contributing_factor_vehicle_4", "contributing_factor_vehicle_5","vehicle_type_code_1", "vehicle_type_code_2", "vehicle_type_code_3", "vehicle_type_code_4", "vehicle_type_code_5"]
	}
}

output {

  #stdout {codec => rubydebug}
  stdout { codec => dots }

  elasticsearch {
    index => "nyc_visionzero"
    template => "./nyc_collision_template.json"
    template_name => "nyc_visionzero"
    template_overwrite => true
    }
}
        EOC
      end

      it "should compile" do
        puts "\n!!!SOURCE!!!"
        puts source
        puts "\n!!!AST!!!"
        puts described_class.compile_ast(source).inspect
        puts "\n!!!IMPERATIVE!!!"
        imp = described_class.compile_imperative(source)
        imp.each {|s,v| puts "\n!#{s}\n"; puts v.to_s}
        puts "\n!!!GRAPH!!!\n"
        puts g = described_class.compile_graph(source)
        g.each {|s,v| puts "\n!#{s}\n"; puts v.to_s}
        puts "\n!!!PIPELINE!!!"
        puts compiled.to_s
      end
    end
  end

  describe "compiling imperative" do
    subject(:source_file) { "fake_sourcefile" }
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

        it "should contain the plugin" do
          expect(c_plugin).to ir_eql(j.iPlugin(INPUT, "generator", {"aarg" => [1],
                                                                "hasharg" => {"foo" => "bar"},
                                                                "iarg" => 123,
                                                                "farg" => 123.123,
                                                                "sarg" => 'hello'}))
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
      let (:c_section) { compiled[section] }

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
          expect(c_section).to ir_eql(compose(
                                        splugin("aplugin", {"count" => 1}),
                                        splugin("aplugin", {"count" => 2})
                                      ))
        end

        it "should attach source_metadata with correct info to the statements" do
          meta = c_section.statements.first.meta
          expect(meta.getSourceText).to eql("aplugin { count => 1 }")
          expect(meta.getSourceLine).to eql(2)
          expect(meta.getSourceColumn).to eql(13)
          expect(meta.getSourceFile).to eql(source_file)
          expect(c_section.statements.first.meta)
          expect(c_section)
        end
      end

      describe "if conditions" do
        describe "conditional expressions" do
          let(:source) { "#{section} { if (#{expression}) { aplugin {} } }" }
          let(:c_expression) { c_section.getBooleanExpression }

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
            expect(c_section).to ir_eql(j.iIf(
                                            j.eEq(j.eEventValue("[foo]"), j.eEventValue("[bar]")),
                                            splugin("grok")
                                          )
                                       )
          end
        end

        describe "only false branch" do
          let (:source) { "#{section} { if [foo] == [bar] { } else { fplugin {} } }" }

          it "should compile correctly" do
            expect(c_section).to ir_eql(j.iIf(
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
            expect(c_section).to ir_eql(j.iIf(
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
            expect(c_section).to ir_eql(j.iIf(
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
            expect(c_section).to ir_eql(j.iIf(
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
            expect(c_section).to ir_eql(j.iIf(
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
            expect(c_section).to ir_eql(j.iIf(
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
