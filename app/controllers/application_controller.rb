class ApplicationController < ActionController::Base
  require 'sinatra'
  require 'line/bot'
  
  before_action :validate_signature

  def validate_signature
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
  end

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      # ローカルで動かすだけならベタ打ちでもOK
      # config.channel_secret = "your channel secret"
      # config.channel_token = "your channel token"
    }
  end
end