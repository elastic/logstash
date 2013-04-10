################################ This plugin was created by Mattia Peterle aka "Bistic, Mattia Beast" ################################ 
####################### Is not very good at programming, but he hoped that it will serve you in the future:) #########################
################################### May you help make this plugin more beautiful and powerful. ####################################### 
####### In accordance with the open-source and the new generations to come, make your contribution useful to the world. Thanks #######

require "logstash/filters/base"
require "logstash/namespace"
require "stringio"

# INFORMATION:
# The filter Advisor is was designed for two important tasks.
# The first job is to collect the events who match a grok word, 
# store it in a buffer and release them after a time_adv time in event form.
# You can manipulate the result with another filter or with outputs, the result of work is signed by tags "advisor_data".
# The second job is to generate other events who explain the number of event that match in time_adv time.
# Is useful if you want to know and manipulate information on outputs of particular events, they are signed by tags "advisor_info".
# A good example is when you want to regard how much events matched after every time_adv and send via mail or sns the informations. 

# INFORMATION ABOUT CLASS:
 
# For do this job, i used some threads that sleep the time_adv assigned,
# the number of threads is equals of number of match instantiated by config.
# I know that logstash use a lot of thread, and in the future i suggest to implement the code and use only one thread for this plugin.
# The number of buffer is the same of match instantiated by config and they works separatly. 
# The buffers works in memory and they dosen't write on disk, i advice you to do some test and see two things:
# How much the buffer can contain events and how much memory used.
# If this result is a piece of shit :D i suggest to implementing a local disk write, because you have two problems:
# First if your logstash crash you lose every event store in buffers, 
# and second, if the time_adv is high, i think the memory of server blow up XD.  

# USAGE:

# This is an example of logstash config:

# filter{
#  advisor {
#     match => [".+ERROR.+",".+WARN.+"] #(optional)
#     time_adv => ["1","2"]             #(optional)
#     format => ["plain"]               #(optional)
#     drop => "true"                    #(optional)
#     notice => "false"                 #(optional)
#  }
# }

# We analize this:

# match => [".+ERROR.+",".+WARN.+"] 
# Means that when events arrive to advisor and they contain a words like "ERROR" or "WARN", they are collect and store in the buffers.
# In particular the events with word"ERROR" are stored in the first buffer and view on outputs when the first time_adv["1"] is triggered,
# same discussion about the events with word "WARN", but triggered with time_adv["2"].
## NOTE: if you have events with words "ERROR" and "WARN" they are stored  in both buffers and viewed in distinct time_adv.
## Match is optional, but if you not define the plugin dosen't do nothing. If defined it must have the same occurances of time_adv.

# time_adv => ["1","2"]
# Means the time when the events matched and collected are pushed on outputs. 
# In this case the events with word "ERROR" are collected and pushed every one minute, same discussion about events with word "WARN",
# but they are collected and pushed every two minutes in this case.

# format => ["plain"] 
# is the format you can decide to store the events who match. For now the best solution is "plain", but you can use json or nil.
# Nil means that the format received is not changed by the filter.

# drop => "true"
# means that you can drop the events who match, for example if you want to view only those later when the time_sdv is triggered.
# If "false" the events who match are collected, but passed through to outputs. In this case is "true", but the dafault is "false".

# notice => "false" 
# means that you can generate special events who can tell you about how much numbers of events match in the time_adv.
# In this case is "false", but default is "true". 

class LogStash::Filters::Advisor < LogStash::Filters::Base

 config_name "advisor"
 plugin_status "experimental"

 ## If you do not set a match or a time_adv the plugin does nothing. If you define must have the same number of occurrences.
 config :match, :validate => :array, :default => []

 ## If you do not set a match or a time_adv the plugin does nothing. If you define must have the same number of occurrences.
 config :time_adv, :validate => :array, :default => []

 # Set the format of events passed to advisor, default "plain".
 config :format, :validate => [ "json", "plain", "nil" ], :default => "plain"

 # Advisor push a special event that explain the numbers of matches when the time_adv trigger. 
 # If you want to push it to outputs set true, default true.
 config :notice, :validate => :boolean, :default => true
 
 # When events arrive to the filters and trigger the match, they can pass through on outputs or drop and show later when advisor wake up, default false.
 config :drop, :validate => :boolean, :default => false

 public
 def register

  # Control the correct config
  if (!(@match.size == 0 || @time_adv.size == 0))

   if(@match.size == @time_adv.size)
   
    require "grok-pure" # rubygem 'jls-grok'
    
    # They are used for store the events that match
    @sbuffer = Array.new(@match.size)
    # They are used for count the number of event match.
    @counter = Array.new(@match.size)
    # They are used for grok the event with match
    @grok = Array.new(@match.size)
    # They are used to signal flush because one thread awake and response of match and time_adv
    @flag = Array.new(@match.size*2)
    # They are used like post timer and see if the buffer is ready
    @thread = Array.new(@match.size)

    # Initialize all:)
    for i in (0..@match.size-1)
     @sbuffer[i] = StringIO.new
     @counter[i] = 0
     @grok[i] = Grok.new
     @grok[i].compile(@match[i].to_s)
     # Initialize Threads
     alert(i)
    end
    # Inizialized flag with double space for a trick used later on flush
    for i in (0..@match.size*2-1)
     @flag[i] = false
    end

   else
    @logger.warn("Match and Time_adv must have the same size!")
   end
  
  else
   @logger.warn("You have not specified Match and Time_adv. This filter will do nothing!")
  end

 end

 # This method is used to launch the Threads. Each Thread sleep the time_adv assigned and then wake up and set flag true. 
 # When signal flag arrive to flush, it generate events.
  def alert(i)
   @thread[i] = time_alert(@time_adv[i].to_i*60) do

   # if buffer is not empty, prepare the flag to flush 
   if(@sbuffer[i].size != 0)
     @flag[i] = true
    end
   end
 end
 
 # This method is used to manage sleep and awaken threads (thanks StackOverflow for the support)
  def time_alert(interval)
   Thread.new do
    loop do
      start_time = Time.now
      yield
      elapsed = Time.now - start_time
      sleep([interval - elapsed, 0].max)
    end
   end
  end

 public
 def filter(event)
  return unless filter?(event)
  
  # Control the correct config
  if(!(@match.size == 0 || @time_adv.size == 0))
    
    if(@match.size == @time_adv.size)

      # Control if an events match 
       for i in (0..@match.size-1)

         if (@grok[i].match(event.to_json))

           # Prepare format of Events recive that match
           if @format == "plain"
             message = self.class.format_message(event)
           elsif @format == "json"
             message = event.to_json
           else
             message = event.to_s
           end

           # puts the event into the string buffer and count it!
           @sbuffer[i] << (message+"\n")
           @counter[i] = @counter[i].to_i + 1
         end
       end
     
      if (@drop == true)
         event.cancel
      end
    
     else
      @logger.warn("Match and Time_adv must have the same size!")
     end

  else
   @logger.warn("You have not specified Match and Time_adv. This filter will do nothing!")
  end
 end

 def self.format_message(event)

    message =  "Date: #{event.timestamp}\n"
    message << "Source: #{event.source}\n"
    message << "Tags: #{event.tags.join(', ')}\n"
    message << "Fields: #{event.fields.inspect}\n"
    message << "Message: #{event.message}\n"

  end

  # This method is used for generate events every 5 seconds (Thanks Jordan Sissel for explanation).
  # In this case we generate an event when advisor thread trigger the flag. 
  # After 5 second of the first event, if notice is active, we generate another events with information about match.
  # We use the same flag, the first part for data, and the second part for notice, here the explained trick.

  def flush
   
   # Control if one or more flags is trigger
   for i in (0..@match.size-1)

         if (@flag[i] == true)

          # if so, gererate an event with message of the buffer
          event_data = LogStash::Event.new
          event_data.source_host = Socket.gethostname
          event_data.message = @sbuffer[i].string+""
          event_data.tags << "advisor_data"
          event_data.source = Socket.gethostname+" advisor_plugin"
          filter_matched(event_data)

          # reset flag and buffer
          @sbuffer[i].truncate(0)
          @sbuffer[i].rewind 
          @flag[i] = false

          # trigger flag notice
          @flag[@match.size+i] = true

          # push the event     
          return [event_data]

         # if flag notice is trigger push another event 
         elsif (@flag[@match.size+i] == true && @notice == true)

          event_info = LogStash::Event.new
          event_info.source_host = Socket.gethostname
          event_info.message = @counter[i].to_s+" events have occurred which match ["+@match[i].to_s+"] during the last "+@time_adv[i].to_s+" minuts\n"
          event_info.tags << "advisor_info"
          event_info.source = Socket.gethostname+" advisor_plugin"
          filter_matched(event_info)
   
          # reset flag and counter 
          @flag[@match.size+i] = false
          @counter[i] = 0

          # push the event
          return [event_info]
         end
    end

   return
  end

end

