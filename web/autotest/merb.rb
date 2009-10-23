# Adapted from Autotest::Rails
require 'autotest'

class Autotest::Merb < Autotest
  
  # +model_tests_dir+::      the directory to find model-centric tests
  # +controller_tests_dir+:: the directory to find controller-centric tests
  # +view_tests_dir+::       the directory to find view-centric tests
  # +fixtures_dir+::         the directory to find fixtures in
  attr_accessor :model_tests_dir, :controller_tests_dir, :view_tests_dir, :fixtures_dir
  
  def initialize
    super
    
    initialize_test_layout
    
    # Ignore any happenings in these directories
    add_exception %r%^\./(?:doc|log|public|tmp)%
    
    # Ignore any mappings that Autotest may have already set up
    clear_mappings
    
    # Any changes to a file in the root of the 'lib' directory will run any 
    # model test with a corresponding name.
    add_mapping %r%^lib\/.*\.rb% do |filename, _|
      files_matching Regexp.new(["^#{model_test_for(filename)}$"])
    end
    
    # Any changes to a fixture will run corresponding view, controller and 
    # model tests
    add_mapping %r%^#{fixtures_dir}/(.*)s.yml% do |_, m|
      [
        model_test_for(m[1]), 
        controller_test_for(m[1]), 
        view_test_for(m[1])
      ]
    end
    
    # Any change to a test or test will cause it to be run
    add_mapping %r%^test/(unit|models|integration|controllers|views|functional)/.*rb$% do |filename, _|
      filename
    end
    
    # Any change to a model will cause it's corresponding test to be run
    add_mapping %r%^app/models/(.*)\.rb$% do |_, m|
      model_test_for(m[1])
    end
    
    # Any change to the global helper will result in all view and controller 
    # tests being run
    add_mapping %r%^app/helpers/global_helpers.rb% do
      files_matching %r%^test/(views|functional|controllers)/.*_test\.rb$%
    end
    
    # Any change to a helper will run it's corresponding view and controller 
    # tests, unless the helper is the global helper. Changes to the global 
    # helper run all view and controller tests.
    add_mapping %r%^app/helpers/(.*)_helper(s)?.rb% do |_, m|
      if m[1] == "global" then
        files_matching %r%^test/(views|functional|controllers)/.*_test\.rb$%
      else
        [
          view_test_for(m[1]), 
          controller_test_for(m[1])
        ]
      end
    end
    
    # Changes to views result in their corresponding view and controller test 
    # being run
    add_mapping %r%^app/views/(.*)/% do |_, m|
      [
        view_test_for(m[1]), 
        controller_test_for(m[1])
      ]
    end
    
    # Changes to a controller result in its corresponding test being run. If 
    # the controller is the exception or application controller, all 
    # controller tests are run.
    add_mapping %r%^app/controllers/(.*)\.rb$% do |_, m|
      if ["application", "exception"].include?(m[1])
        files_matching %r%^test/(controllers|views|functional)/.*_test\.rb$%
      else
        controller_test_for(m[1])
      end
    end

    # If a change is made to the router, run all controller and view tests
    add_mapping %r%^config/router.rb$% do # FIX
      files_matching %r%^test/(controllers|views|functional)/.*_test\.rb$%
    end

    # If any of the major files governing the environment are altered, run 
    # everything
    add_mapping %r%^test/test_helper.rb|config/(init|rack|environments/test.rb|database.yml)% do # FIX
      files_matching %r%^test/(unit|models|controllers|views|functional)/.*_test\.rb$%
    end
  end
  
private

  # Determines the paths we can expect tests or specs to reside, as well as 
  # corresponding fixtures.
  def initialize_test_layout
    self.model_tests_dir      = "test/unit"
    self.controller_tests_dir = "test/functional"
    self.view_tests_dir       = "test/views"
    self.fixtures_dir         = "test/fixtures"
  end
  
  # Given a filename and the test type, this method will return the 
  # corresponding test's or spec's name.
  # 
  # ==== Arguments
  # +filename+<String>:: the file name of the model, view, or controller
  # +kind_of_test+<Symbol>:: the type of test we that we should run
  # 
  # ==== Returns
  # String:: the name of the corresponding test or spec
  # 
  # ==== Example
  # 
  #   > test_for("user", :model)
  #   => "user_test.rb"
  #   > test_for("login", :controller)
  #   => "login_controller_test.rb"
  #   > test_for("form", :view)
  #   => "form_view_spec.rb" # If you're running a RSpec-like suite
  def test_for(filename, kind_of_test)
    name  = [filename]
    name << kind_of_test.to_s if kind_of_test == :view
    name << "test"
    return name.join("_") + ".rb"
  end
  
  def model_test_for(filename)
    [model_tests_dir, test_for(filename, :model)].join("/")
  end
  
  def controller_test_for(filename)
    [controller_tests_dir, test_for(filename, :controller)].join("/")
  end
  
  def view_test_for(filename)
    [view_tests_dir, test_for(filename, :view)].join("/")
  end
  
end