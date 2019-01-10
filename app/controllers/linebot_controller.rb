class LinebotController < ApplicationController
  require 'sinatra'
  require 'line/bot'
  require 'active_support/core_ext/numeric/conversions'

  protect_from_forgery :except => [:callback]

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
      when Line::Bot::Event::Postback
        data = event['postback']['data']
        if data.include?("action=join")
          join(event)
        elsif data.include?("action=payments_index")
          payments_index_carousel(event)
        elsif data.include?("action=check")
          check(event)
        elsif data.include?('payout')
          payout(event)
        elsif data.include?("action=delete_confirm")
          payment_id = data.match(/payment_id=(.*)/)[1]
          delete_confirm(event, payment_id)
        elsif data.include?("action=delete_payment")
          payment_id = data.match(/payment_id=(.*)/)[1]
          delete_payment(event, payment_id)
        end
      end
    end

    "OK"
  end


  def delete_confirm(event, payment_id)
    payment = Payment.find(payment_id)
    reply_content(event, {
      type: 'template',
      altText: '削除確認',
      template: {
        type: 'confirm',
        text: "#{payment.title}を削除しますか？",
        actions: [
          {label: 'はい', type: 'postback', data: "action=delete_payment&payment_id=#{payment_id}"},
          {label: 'いいえ', type: 'message', text: 'No!'}
        ]
      }
    })
  end

  def delete_payment(event, payment_id)
    payment = Payment.find(payment_id)
    payment.destroy
    reply_text(event, "#{payment.title}を削除しました。")
  end

  def handle_message(event)
    case event.type
    when Line::Bot::Event::MessageType::Text
      case event.message['text']
      when '殿'
        reply_content(event, {
          type: 'template',
          altText: 'ご用件は？',
          template: {
            type: 'buttons',
            text: 'ご用件は？',
            actions: [
              { label: '割り勘に参加する', type: 'uri', uri: 'line://app/1632988548-YR6QRBw4' },
              { label: '支払いを登録する', type: 'uri', uri: 'line://app/1632988548-1axlpDN3' },
              { label: '明細を見る', type: 'postback', data: 'action=payments_index' },
              { label: '精算する', type: 'postback', data: 'action=check' },
            ]
          }
        })

      when '割り勘'
        reply_content(event, {
          type: 'template',
          altText: 'ご用件は？',
          template: {
            type: 'buttons',
            text: 'ご用件は？',
            actions: [
              { label: '割り勘に参加する', type: 'uri', uri: 'line://app/1632988548-YR6QRBw4' },
              { label: '支払いを登録する', type: 'uri', uri: 'line://app/1632988548-1axlpDN3' },
              { label: '明細を見る', type: 'postback', data: 'action=payments_index' },
              { label: '精算する', type: 'postback', data: 'action=check' },
            ]
          }
        })

      when '▶︎はい'
        checkout(event)

      when '▶︎精算'
        check(event)
      end


    end
  end

  def set_room(event)
    room = Room.create(room_id: event['source']['roomId'] || event['source']['groupId'])
    message = [
      {type: 'text',
      text: "warikanの使い方\n\n「割り勘」とメッセージを送信するとメニューが開きます。\n\nまずはメンバー全員が下の「割り勘に参加する」をタップしてください。"},
      {type: 'template',
      altText: '割り勘に参加する',
      template: {
        type: 'buttons',
        text: '下のボタンをタップしてください。',
        actions: [
          { label: '割り勘に参加する', type: 'uri', uri: 'line://app/1632988548-YR6QRBw4' },
        ],
      }}
    ]
    client.reply_message(event['replyToken'], message)
  end

  def join(event)
    user = User.new
    user.user_id = event['source']['userId']
    user.room_id = event['source']['roomId'] || event['source']['groupId']
    response = client.get_profile(event['source']['userId'])
    profile = JSON.parse(response.read_body)
    user.name = profile['displayName']
    if user.save
      room = Room.find_by(room_id: user.room_id)
      room.number_of_members += 1
      room.save
      reply_text(event, "#{user.name}さんが参加しました。")
    else
      reply_text(event, "#{user.name}さんはすでに参加済です。")
    end
  end

  def payments_index_carousel(event)
    room = Room.find_by(room_id: event['source']['roomId'] || event['source']['groupId'])
    total_price = Payment.where('room_id = ? and check_id = ?', room.room_id, room.check_id).sum(:price)
    price_per_person = total_price / room.number_of_members
    contents = []
    first_carousel_contents = [
      {
        type: "text",
        text: "明細",
        size: "lg"
      },
      {
        type: "text",
        text: "合計金額: #{total_price.to_s(:delimited)}円",
        margin: "xl"
      },
      {
        type: "text",
        text: "一人当たり: #{price_per_person.to_s(:delimited)}円",
        margin: "xl"
      },
      {
        type: "text",
        text: "個人の支払い合計金額",
        margin: "xl"
      }
    ]
      User.where(room_id: room.room_id).each do |user|
        user_total_price = Payment.where('room_id = ? and check_id = ? and payer_id = ?', room.room_id, room.check_id, user.user_id).sum(:price)
        user_total = {
          type: "text",
          text: "#{user.name}: #{user_total_price.to_s(:delimited)}円",
        }
        first_carousel_contents.push(user_total)
      end

    first_carousel = {
      type: "bubble",
      body: {
        type: "box",
        layout: "vertical",
        contents: first_carousel_contents
      }
    }
    contents.push(first_carousel)

    User.where(room_id: room.room_id).each do |user|
      user_payments = [
        {
          type: "text",
          text: "#{user.name}さんの支払い",
          size: "lg"
        }
      ]
      Payment.where('room_id = ? and check_id = ? and payer_id = ?', room.room_id, room.check_id, user.user_id).each do |payment|
        user_payment = {
          type: "button",
          height: "sm",
          action: {
            label: "#{payment.title}: #{payment.price.to_s(:delimited)}円",
            type: "postback",
            data: "action=delete_confirm&payment_id=#{payment.id}"
          }
        }
        user_payments.push(user_payment)
      end

      user_carousel = {
        type: "bubble",
        body: {
          type: "box",
          layout: "vertical",
          contents: user_payments
        }
      }
      contents.push(user_carousel)
    end



    message = [
      {
        type: "flex",
        altText: "明細",
        contents: {
          type: "carousel",
          contents: contents
        }
      },
      {
        type: "text",
        text: "支払いをタップすると削除することができます。"

      }
    ]
    client.reply_message(event['replyToken'], message)
  end

  def check(event)
    dept_text = ""
    room = Room.find_by(room_id: event['source']['roomId'] || event['source']['groupId'])
    total_price = Payment.where('room_id = ? and check_id = ?', room.room_id, room.check_id).sum(:price)
    price_per_person = total_price / room.number_of_members
    User.where(room_id: room.room_id).each do |user|
      #ユーザーごとの支払い合計額
      payment_price_by_user = Payment.where('payer_id = ? and room_id = ? and check_id = ?', user.user_id, room.room_id, room.check_id).sum(:price)
      dept = price_per_person - payment_price_by_user
      if dept < 0
        dept = -dept
        dept_text += "#{user.name}は#{dept.to_s(:delimited)}円もらう\n"
      elsif dept > 0
        dept_text += "#{user.name}は#{dept.to_s(:delimited)}円払う\n"
      else
        dept_text += "#{user.name}は貸し借りが0円\n"
      end
    end
    message = [
      {
        type: 'text',
        text: dept_text
      },
      {
        type: 'template',
        altText: '精算終了しますか？',
        template: {
          type: 'confirm',
          text: '精算終了して会計をリセットしますか？',
          actions: [
            { label: 'はい', type: 'postback', data: 'payout' },
            { label: 'いいえ', type: 'message', text: '▶︎いいえ' },
          ]
        }
      }
    ]
    client.reply_message(event['replyToken'], message)
  end

  def payout(event)
    room = Room.find_by(room_id: event['source']['roomId'] || event['source']['groupId'])
    room.check_id += 1
    room.save
    reply_text(event, "会計をリセットしました。")
  end


private
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def user_params
    params.require(:user).permit(:user_id, :room_id, :name)
  end

end
