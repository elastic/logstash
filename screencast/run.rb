#!/usr/bin/env ruby
#

require "rubygems"
require "ap"

#if ENV["DISPLAY"] != ":1" 
  #puts "$DISPLAY is wrong."
  #exit 1
#end

def type(string)
  system("xdotool", "type", "--clearmodifiers", "--delay", "100", string)
  puts "Typing: #{string}"
  #puts string.inspect
  #$stdout.flush
end

def run(string)
  command = string[3..-1].chomp
  system(command)
end

def key(string)
  keyseq = string[3..-1].chomp.split(/ +/)
  system("xdotool", "key", "--clearmodifiers",  *keyseq)
  puts keyseq.inspect
  #puts string.inspect
  #$stdout.flush
end

handlers = [
  [/^[,]/m, proc { |s| type(s); sleep(0.4) } ], # comma
  [/^[.;:?!]+/m, proc { |s| type(s); sleep(1) } ], # punctuation
  [/^[\n]{2}/m, proc { |s| type(s); sleep(1) } ], # new paragraph
  #[/^[\n](?! *[*-])/m, proc { |s| type(" ") } ], # continuation of a paragraph
  #[/^[\n](?= *[*-])/m, proc { |s| type("\n") } ], # lists or other itemized things
  [/^[\n]/m, proc { |s| type(s) } ], # lists or other itemized things
  [/^%E[^\n]*\n/m, proc { |s| run(s) } ], # execute a command
  [/^%K[^\n]*\n/m, proc { |s| key(s) } ], # type a specific keystroke
  [/^[^,.;:?!\n]+/m, proc { |s| type(s) } ], # otherwise just type it
] 

data = $stdin.read
while data.length > 0
  match, func = handlers.collect { |re, f| [re.match(data), f] }\
                        .select { |m,f| m.begin(0) == 0 rescue false }.first
  str = match.to_s
  func.call(str)
  $stdout.flush
  #sleep 3
  data = data[match.end(0)..-1]
end
