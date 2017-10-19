require 'unisender_rails/sender'
require 'unisender_rails/version'

module UnisenderRails
  module Installer
    extend self

    def install
      ActionMailer::Base.add_delivery_method :unisender, UnisenderRails::Sender
    end
  end
end

UnisenderRails::Installer.install
