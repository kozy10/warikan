Rails.application.routes.draw do
	root to: 'linebot#index'
  post '/callback' => 'linebot#callback'
end
