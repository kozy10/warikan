Rails.application.routes.draw do
	post '/callback' => 'linebot#callback'
	resources :payments, only: [:new, :create, :edit, :update]
	resources :users, only: [:new, :create]
	get '/users/complete' => 'users#complete'
end
