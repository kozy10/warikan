Rails.application.routes.draw do
	post '/callback' => 'linebot#callback'
	root to: 'linebot#index'
end
