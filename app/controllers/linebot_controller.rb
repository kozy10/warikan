class LinebotController < ApplicationController
  protect_from_forgery :except => [:callback]

  def index
    render ''
  end

  def reply_text(event, texts)
    texts = [texts] if texts.is_a?(String)
    client.reply_message(
      event['replyToken'],
      texts.map { |text| {type: 'text', text: text} }
    )
  end

  def reply_content(event, messages)
    res = client.reply_message(
      event['replyToken'],
      messages
    )
    puts res.read_body if res.code != 200
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        handle_message(event)
      else
        reply_text(event, "Unknown event type: #{event}")
      end
    end

    "OK"
  end

  def handle_message(event)
    case event.type
    when Line::Bot::Event::MessageType::Text
      case event.message['text']
      when 'profile'
        if event['source']['type'] == 'user'
          profile = client.get_profile(event['source']['userId'])
          profile = JSON.parse(profile.read_body)
          reply_text(event, [
            "Display name\n#{profile['displayName']}",
            "Status message\n#{profile['statusMessage']}"
          ])
        else
          reply_text(event, "Bot can't use profile API without user ID")
        end

       when 'buttons'
        reply_content(event, {
          type: 'template',
          altText: 'Buttons alt text',
          template: {
            type: 'buttons',
            thumbnailImageUrl: THUMBNAIL_URL,
            title: 'My button sample',
            text: 'Hello, my button',
            actions: [
              { label: '追加する', type: 'uri', uri: 'https://tranquil-mountain-71170/index' },
              { label: 'Send postback', type: 'postback', data: 'hello world' },
              { label: 'Send postback2', type: 'postback', data: 'hello world', text: 'hello world' },
              { label: 'Send message', type: 'message', text: 'This is message' }
            ]
          }
        })


      when 'warikan'
        reply_content(event, {
          type: 'text',
          text: '[QUICK REPLY]',
          quickReply: {
            items: [
              # {
              #   type: "action",
              #   action: {
              #     type: "uri",
              #     label: "追加",
              #     uri: 'https://line.me'
              #   }
              # },
              {
                type: "action",
                action: {
                  type: "message",
                  label: "Sushi",
                  text: "Sushi"
                }
              },
              {
                type: "action",
                action: {
                  type: "message",
                  label: "Yes",
                  text: "Yes"
                }
              },
            ],
          },
        })

      when 'bye'
        case event['source']['type']
        when 'user'
          reply_text(event, "[BYE]\nBot can't leave from 1:1 chat")
        when 'group'
          reply_text(event, "[BYE]\nLeaving group")
          client.leave_group(event['source']['groupId'])
        when 'room'
          reply_text(event, "[BYE]\nLeaving room")
          client.leave_room(event['source']['roomId'])
        end

      else
        reply_text(event, "[ECHO]\n#{event.message['text']}")

      end
    else
      puts "Unknown message type: #{event.type}"
      reply_text(event, "[UNKNOWN]\n#{event.type}")
    end
  end
end