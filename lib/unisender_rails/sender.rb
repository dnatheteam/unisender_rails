require 'uni_sender'

module UnisenderRails
  class Sender

    def initialize(args)
      @settings = { api_key: nil }
      args.each do |arg_name, arg_value|
        @settings[arg_name.to_sym] = arg_value
      end
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

    private

    def settings
      @settings
    end

    def client
      @client
    end

    def deliver_email!(mail)
      mail_to = [*(mail.to)]
      list_id = settings[:list_id]
      client.subscribe fields: { email: mail_to }, list_ids: list_id, double_optin: 3
      client.sendEmail subject: mail.subject,
                       body: mail.body,
                       sender_email: mail.from,
                       email: mail_to,
                       sender_name: @settings[:sender_name] || mail.from.split('@').first,
                       list_id: list_id,
                       lang: @settings[:lang] || 'ru'
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
      result = client.createEmailMessage(email_options)['result']
      client.createCampaign message_id: result['message_id'],
                            contacts: mail_to.join(','),
                            defer: 1
    end

  end
end
