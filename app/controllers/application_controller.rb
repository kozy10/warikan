class ApplicationController < ActionController::Base
end

require 'line/bot'
require 'sinatra' 

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

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
      # ローカルで動かすだけならベタ打ちでもOK
      config.channel_secret = "your channel secret"
      config.channel_token = "your channel token"
    }
  end
end
