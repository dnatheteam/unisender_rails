require 'uni_sender'

module UnisenderRails
  class Sender

    attr_reader :settings

    def initialize(args)
      @settings = { api_key: nil }
      args.each do |arg_name, arg_value|
        @settings[arg_name.to_sym] = arg_value
      end
      @logger = @settings[:logger] || Rails.logger
      @client = UniSender::Client.new(@settings[:api_key])
    end

    def deliver!(mail)
      mail_to = [*mail.to]
      if mail_to.length == 1
        deliver_email!(mail)
      else
        deliver_emails!(mail)
      end
    end

    def deliver_email!(mail)
      mail_to = [*(mail.to)].first
      list_id = @settings[:list_id]
      result = @client.subscribe fields: { email: mail_to }, list_ids: list_id, double_optin: 3
      @logger.info "UNISENDER:Subscribe '#{mail_to}' "
      @logger.info "UNISENDER:response #{result}"
      send_params = {
        subject: mail.subject,
        body: mail.body,
        sender_email: mail.from,
        email: mail_to,
        sender_name: @settings[:sender_name] || mail.from.split('@').first,
        list_id: list_id,
        lang: @settings[:lang] || 'ru'
      }
      result = @client.sendEmail send_params
      @logger.info "UNISENDER:sendMail #{send_params}"
      @logger.info "UNISENDER:response #{result}"

    end

    def deliver_emails!(mail)
      mail_to = [*(mail.to)]
      email_options = {
        sender_name: @settings[:sender_name] || mail.from.split('@').first,
        sender_email: mail.from,
        subject: mail.subject,
        list_id: @settings[:list_id],
        generate_text: 1,
        lang: @settings[:lang] || 'ru',
        body: mail.body
      }
      result = @client.createEmailMessage(email_options)
      @logger.info "UNISENDER:createEmailMessage #{email_options}"
      @logger.info "UNISENDER:response #{result}"
      create_campaign_params = {
        message_id: result['result']['message_id'],
        contacts: mail_to.join(','),
        defer: 1
      }
      result = @client.createCampaign create_campaign_params
      @logger.info "UNISENDER:createCampaign #{email_options}"
      @logger.info "UNISENDER:response #{result}"
    end

  end
end
