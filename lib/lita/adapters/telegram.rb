module Lita
  module Adapters
    class Telegram < Adapter
      attr_reader :client

      config :telegram_token, type: String, required: true

      def initialize(robot)
        super
        @client = ::Telegram::Bot::Client.new(config.telegram_token, logger: ::Logger.new($stdout))
      end

      def run
        client.listen do |message|
          user = Lita::User.find_by_name(message.from.username)
          user = Lita::User.create(message.from.username) unless user

          chat = Lita::Room.new(message.chat.id)

          source = Lita::Source.new(user: user, room: chat)

          message.text ||= ''
          msg = Lita::Message.new(robot, message.text, source)

          robot.receive(msg)
        end
      end

      def send_messages(target, messages)
        messages.each do |message|
          typing(target)
          if message.is_a?(String)
            client.api.sendMessage(chat_id: target.room.to_i, text: message)
            # markup = ::Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(A B), %w(C D)], one_time_keyboard: true)
            # client.api.sendMessage(chat_id: target.room.to_i, text: message[:text], reply_markup: markup)
            # send_markup(chat_id: target.room.to_i, response: message)
          elsif message.is_a?(Hash)
            client.api.sendMessage(chat_id: target.room.to_i, **message)
          else
            next
          end
        end
      end

      def typing(target)
        client.api.sendChatAction(chat_id: target.room.to_i, action: 'typing')
      end

      def shutdown
        Lita.logger.info 'Shutting Down...'
        robot.trigger(:disconnected)
      end

      Lita.register_adapter(:telegram, self)
    end
  end
end
