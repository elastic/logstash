namespace "cops" do

  desc "run rubocop to enforce style checks"
  task "rubocop" do
    require "rubocop"
    options = ['--format', 'simple']
    cli = RuboCop::CLI.new
    puts('Running RuboCop...')
    result = cli.run(options)
    abort('RuboCop failed!') if !(result == 0)
  end

end
