AsyncRequest::Engine.routes.draw do
  resources :jobs, only: [:show]
  get '/jobs(?id=:id)', to: 'jobs#show', as: 'jobs'
end
