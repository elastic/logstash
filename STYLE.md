Rather than write a style guide, please follow by examples you see in the code.
If you send me a patch, I will not reject it for style reasons (but I will fix
it before it gets committed) 

* indentation: 2 spaces
* between methods: 1 line
* sort your requires
* long lines should wrap at 80 characters. If you wrap at an operator (or, +,
  etc) start the next line with that operator.
* explicit is better than implicit

The point is consistency and documentation. If you see inconsistencies, let me
know, and I'll fix them :)

Short example:

require "something from a gem" # from gem 'thing'

# some documentation about this class
class Foo < Bar
  # some documentation about this function
  def somefunc(arg1, arg2, arg3)
    # comment
    puts "Hello"
    if (some_long_condition \
        or some_other_condition)
      puts "World"
    end # if <very short description>

    # Long lines should wrap and start with an operator if possible.
    foo = some + long + formula + thing \
          + stuff + bar;

    # Function calls, when wrapping, should align to the '(' where reasonable.
    some_function_call(arg1, arg2, arg3, some_long_thing,
                       alignment_here, arg6)
    # If it seems unreasonable, wrap and indent 4 spaces.
    some_really_long_function_call_blah_blah_blah(arg1,
        arg2, arg3, arg4)
      
  end # def somefunc
end # class Foo
