class LinebotController < ApplicationController
  require 'sinatra'
  require 'line/bot'
  protect_from_forgery :except => [:callback]

  def set_room(event)
    room = Room.create(room_id: event['source']['roomId'])
  end

  def reply_text(event, text)
    message = {
      type: 'text',
      text: text
    }
    client.reply_message(event['replyToken'], message)
  end

  def reply_content(event, messages)
    res = client.reply_message(
      event['replyToken'],
      messages
    )
    puts res.read_body if res.code != 200
  end

  def payments_index(event)
    payments_text = ""
    total_price = 0
    room = Room.find_by(room_id: event['source']['roomId'])
    Payment.where('room_id = ? and check_id = ?', room.room_id, room.check_id).each do |p|
      title = p.title
      price = p.price
      payment_text = "#{p.payer.name}\n#{title}  #{price}円\n\n"
      payments_text += payment_text
      total_price += price
    end

    price_per_person = total_price / room.number_of_members
    payments_text += "\n----------\n合計金額: #{total_price}円\n1人あたり: #{price_per_person}円"
    message = {
      type: 'text',
      text: payments_text
    }
    client.reply_message(event['replyToken'], message)
  end

  def check(event)
    dept_text = ""
    room = Room.find_by(room_id: event['source']['roomId'])
    total_price = Payment.where('room_id = ? and check_id = ?', room.room_id, room.check_id).sum(:price)
    price_per_person = total_price / room.number_of_members
    User.where(room_id: event['source']['roomId']).each do |user|
      #ユーザーごとの支払い合計額
      payment_price_by_user = Payment.where('payer_id = ? and room_id = ? and check_id = ?', user.user_id, room.room_id, room.check_id).sum(:price)
      dept = price_per_person - payment_price_by_user
      if dept < 0
        dept_text += "#{user.name}は#{-dept}円もらう\n"
      elsif dept > 0
        dept_text += "#{user.name}は#{dept}円払う\n"
      else
        dept_text += "#{user.name}は貸し借りが0円\n"
      end
    end
    message = [
      {type: 'text',
      text: dept_text},
      {type: 'template',
      altText: '清算終了しますか？',
      template: {
        type: 'confirm',
        text: '清算終了しますか？',
        actions: [
          { label: 'はい', type: 'message', text: '▶︎はい' },
          { label: 'いいえ', type: 'message', text: '▶︎いいえ' },
        ],
      }}
    ]
    client.reply_message(event['replyToken'], message)
  end

  def checkout(event)
    room = Room.find_by(room_id: event['source']['roomId'])
    room.check_id += 1
    room.save
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
      when Line::Bot::Event::Join
        set_room(event)
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

      when '@warikan'
        reply_content(event, {
          type: 'template',
          altText: 'ご用件は？',
          template: {
            type: 'buttons',
            text: 'ご用件は？',
            actions: [
              { label: '登録', type: 'uri', uri: 'line://app/1632988548-zW1VrG6k' },
              { label: '追加', type: 'uri', uri: 'line://app/1632988548-8MyJAo9Z' },
              { label: '明細', type: 'message', text: '▶︎明細' },
              { label: '清算', type: 'message', text: '▶︎清算' },
            ]
          }
        })

      when '▶︎明細'
        payments_index(event)

      when '▶︎清算'
        check(event)

      when '▶︎はい'
        checkout(event)


      end
    end
  end

private
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
  
end
