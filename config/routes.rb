AsyncRequest::Engine.routes.draw do
  resources :jobs, only: [:show]
  get '/jobs', to: 'jobs#show'
end
