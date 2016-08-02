# encoding: utf-8
#
# This make the test suite non thread safe.
def capture(&block)
  old_stdout = $stdout

  begin
    $stdout = StringIO.new
    block.call
    return $stdout.string
  ensure
    $stdout = old_stdout
  end
end
