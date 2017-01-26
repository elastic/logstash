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

        get "/:id" do
          respond_with(@command.get_info(params[:id]))
        end

        delete "/:id" do
          respond_with(@command.delete(params[:id]))
        end

        post "/_rollover/:new_id" do
          respond_with(@command.rollover(params[:new_id]))
        end
      end
    end
  end
end
