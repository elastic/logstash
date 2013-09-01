require "logstash/filters/base"
require "logstash/namespace"

# INFORMATION:
# The filter Advisor is designed for capture and confrontation the events. 
# The events must be grep by a filter first, then it can pull out a copy of it, like clone, whit tags "advisor_first",
# this copy is the first occurrence of this event verified in time_adv.
# After time_adv Advisor will pull out an event tagged "advisor_info" who will tell you the number of same events verified in time_adv.

# INFORMATION ABOUT CLASS:
 
# For do this job, i used a thread that will sleep time adv. I assume that events coming on advisor are tagged, then i use an array for storing different events.
# If an events is not present on array, then is the first and if the option is activate then  advisor push out a copy of event.
# Else if the event is present on array, then is another same event and not the first, let's count it.  

# USAGE:

# This is an example of logstash config:

# filter{
#  advisor {
#     time_adv => 1                     #(optional)
#     send_first => true                #(optional)
#  }
# }

# We analize this:

# time_adv => 1
# Means the time when the events matched and collected are pushed on outputs with tag "advisor_info".

# send_first => true
# Means you can push out the first events different who came in advisor like clone copy and tagged with "advisor_first"

class LogStash::Filters::Advisor < LogStash::Filters::Base

 config_name "advisor"
 milestone 1

 # If you do not set time_adv the plugin does nothing.
 config :time_adv, :validate => :number, :default => 0
 
 # If you want the first different event will be pushed out like a copy
 config :send_first, :validate => :boolean, :default => true
 
 public
 def register

  # Control the correct config
  if (!(@time_adv == 0))
    
    @flag = false
    @first = false
    # Is used for store the different events.
    @sarray = Array.new
    # Is used for count the number of equals events.
    @carray = Array.new

    @thread = time_alert(@time_adv.to_i*60) do
     # if collected any events then pushed out a new event after time_adv
     if (@sarray.size !=0) 
        @flag = true
     end
    end
  
  else
   @logger.warn("Advisor: you have not specified Time_adv. This filter will do nothing!")
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
  if(!(@time_adv == 0))

    new_event = true
    @message = event["message"]
    
    # control if the events are new or they are came before
    for i in (0..@sarray.size-1)
      if (@message == @sarray[i].to_s)
        @logger.debug("Avisor: Event match")
        # if came before then count it
        new_event = false
        @carray[i] = @carray[i].to_i+1
        @logger.debug("Advisor: "+@carray[i].to_s+" Events matched")
        break
      end
    end
     
    if (new_event == true)
       # else is a new event

       @sarray << @message
       @carray << 1
       if (send_first == true)
           @logger.debug("Advisor: is the first to send out")
           @first = true
       end
    end
     
  else
   @logger.warn("Advisor: you have not specified Time_adv. This filter will do nothing!")
  end
 end


  # This method is used for generate events every 5 seconds (Thanks Jordan Sissel for explanation).
  # In this case we generate an event when advisor thread trigger the flag or is the first different event. 

  def flush
      
        if (@first == true)
          event = LogStash::Event.new
          event.source_host = Socket.gethostname
          event["message"] = @message
          event.tags << "advisor_first"
          event.source = Socket.gethostname+" advisor_plugin"
          filter_matched(event)
         
          @first = false
          return [event]
        end
   
         if (@flag == true)
 
          if (@tags.size != 0)
            @tag_path = ""
            for i in (0..@tags.size-1)
              @tag_path += @tags[i].to_s+"."
            end
          end
            
          # Prepare message 
          message = "Advisor: Found events who match: "+@tag_path.to_s+"\n\n"

          # See on messagge partial part of different events
          for i in (0..@sarray.size-1)
            message = message+@carray[i].to_s+" events like: "+(@sarray[i].to_s).slice(0, 300)+"\n\n"
          end
         
          event = LogStash::Event.new
          event["host"] = Socket.gethostname 
          event["message"] = message  
          event.tag << "advisor_info"
          filter_matched(event)
   
          # reset flag and counter 
          @flag = false
          @carray = nil
          @sarray = nil
          @carray = Array.new
          @sarray = Array.new

          # push the event
          return [event]
         end
    return
 
  end

end
# By Bistic:)
