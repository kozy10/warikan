class LinebotController < ApplicationController

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def index
  end

  def callback
    body = request.body.read
    events = client.parse_events_from(body)

    events.each { |event|
      # イベントがメッセージで
      case event
      when Line::Bot::Event::Message
        # イベントのタイプがテキストのとき
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: "何か御用でござるか？",
            "quickReply": { 
              "items": [
                {
                  "type": "action", 
                  "action": {
                    "type": "message",
                    "label": "追加",
                    "text": "追加"
                  }
                },
                {
                  "type": "action",
                  "action": {
                    "type": "message",
                    "label": "明細",
                    "text": "明細"
                  }
                },
                {
                  "type": "action", 
                  "action": {
                    "type": "message",
                    "label": "清算",
                    "text": "清算"
                  }
                }
              ]
            }
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }

    head :ok
  end
end