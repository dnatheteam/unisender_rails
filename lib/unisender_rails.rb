require "unisender_rails/version"

module UnisenderRails
  module Installser
    extend self

    def install
      ActionMailer::Base.add_delivery_method :unisender, UnisenderRails::Sender
    end
  end
end

UnisenderRails::Installser.install
