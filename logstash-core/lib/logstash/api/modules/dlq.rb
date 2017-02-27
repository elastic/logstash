# encoding: utf-8
module LogStash
  module Api
    module Modules
      class Dlq < ::LogStash::Api::Modules::Base

        before do
          @command = factory.build(:dlq)
        end

        get "/" do
          respond_with(@command.list())
        end
      end
    end
  end
end
