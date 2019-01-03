Rails.application.routes.draw do
	post '/callback' => 'linebot#callback'
	resources :payments, only: [:new, :create]
	resources :users, only: [:new, :create]
end
