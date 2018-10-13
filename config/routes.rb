Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'

  resource :resume, only: [:show]
  resource :about, only: [:show]

  resources :users, only: [:new, :create, :show]

  resources :workouts, only: [:index, :show, :update, :new, :create] do
    resources :track_intervals, only: [:new, :create]
  end

  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  namespace :elm_demo do
    root 'base#index'
  end

  namespace :api do
  end
end
