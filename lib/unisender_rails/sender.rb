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
      @users = @settings[:users_model].where(email: mail_to)
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
        lang: @settings[:lang] || 'ru',
        track_read: @settings[:track_read],
        track_links: @settings[:track_links]
      }
      result = @client.sendEmail send_params
      @logger.info "UNISENDER:sendMail #{send_params}"
      @logger.info "UNISENDER:response #{result}"
    end

    def deliver_emails!(mail)
      mail_to = [*(mail.to)]
      return if mail_to.blank?
      return if @users.blank?
      list_id = create_list(mail.subject)
      subscribe_users(list_id, @users)
      message_id = create_email_message(list_id, mail)
      create_campaign(message_id, mail_to)
    end

    def create_list(subject)
      list_options = "#{subject} #{Date.today}"
      @logger.info "UNISENDER:createList #{list_options}"
      list = @client.createList(title: list_options)
      @logger.info "UNISENDER:response #{list}"
      list['result']['id']
    end

    def subscribe_users(list_id, users)
      users.in_batches(of: 500) do |batch| 
        data = batch.map { |user| convert_to_export_format(list_id, user) }
        fields = %w[email email_status email_availability Name email_list_ids] 
        @client.importContacts(field_names: fields, data: data)
        sleep 35
      end
    end

    def convert_to_export_format(list_id, user)
      [
        user.email,
        'active',
        'available',
        user.printable_name,
        list_id
      ]
    end

    def create_email_message(list_id, mail)
      email_options = {
        sender_name: @settings[:sender_name] || mail.from.split('@').first,
        sender_email: mail.from,
        subject: mail.subject,
        list_id: list_id,
        generate_text: 1,
        lang: @settings[:lang] || 'ru',
        body: mail.body,
      }
      @logger.info "UNISENDER:createEmailMessage #{email_options}"
      result = @client.createEmailMessage(email_options)
      @logger.info "UNISENDER:response #{result}"
      result['result']['message_id']
    end

    def create_campaign(message_id, mail_to)
      create_campaign_params = {
        message_id: message_id,
        contacts: mail_to.join(','),
        defer: 1,
        track_ga: @settings[:track_ga],
        ga_medium: @settings[:email],
        ga_source: @settings[:adoption],
        ga_campaign: @settings[:adoption],
        track_read: @settings[:track_read],
        track_links: @settings[:track_links]
      }
      @logger.info "UNISENDER:createCampaign #{create_campaign_params}"
      result = @client.createCampaign create_campaign_params
      @logger.info "UNISENDER:response #{result}"
    end
  end
end

