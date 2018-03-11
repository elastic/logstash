module ::LogStash; module Plugins; module Builtin; module Internal; class Output < ::LogStash::Outputs::Base
  include org.logstash.plugins.internal.InternalOutput

  config_name "internal"

  concurrency :shared

  config :send_to, :validate => :string, :required => true, :list => true

  def register
    @address_receivers = java.util.concurrent.ConcurrentHashMap.new
    org.logstash.plugins.internal.Common.register_sender(@send_to, self)
  end

  def updateAddressReceiver(address, function)
    @address_receivers[address] = function
  end

  def removeAddressReceiver(address, function)
    @address_receivers.remove(address)
  end

  NO_LISTENER_LOG_MESSAGE = "Internal output to address waiting for listener to start"
  def multi_receive(events)
    @send_to.each do |address|
      events.each do |e|
        event_clone = e.clone;
        while !apply_address_receiver(address, event_clone)
          byRunState = org.logstash.plugins.internal.Common.addressesByRunState
          @logger.info(
            NO_LISTENER_LOG_MESSAGE,
            :destination_address => address,
            :registered_addresses => {:running => byRunState.running, :not_running => byRunState.notRunning}
          )
          sleep 1
        end
      end
    end
  end

  def apply_address_receiver(address, event)
    receiver = @address_receivers[address]
    receiver.nil? ? nil : receiver.apply(event)
  end

  def pipeline_shutting_down?
    execution_context.pipeline.inputs.all? {|input| input.stop?}
  end

  def close
    # Tried to do this with a static method on Common, but somehow jruby kept saying there weren't
    # enough arguments provided for reasons that make no sense. Probable JRuby bug here
    @send_to.each do |address|
        org.logstash.plugins.internal.Common.ADDRESS_STATES.compute(address, proc {|a, state|
          state.getOutputs.remove(self);
          return state;
      })
      output.removeAddressReceiver(address);
    end
  end
end; end; end; end; end