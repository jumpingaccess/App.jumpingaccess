# config/routes.rb
Rails.application.routes.draw do
  root to: redirect('/login')
  get "up" => "rails/health#show", as: :rails_health_check

  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :password_resets, only: [:new, :create]

  get "/password_resets/edit", to: "password_resets#edit", as: :edit_password_reset
  
  patch "/password_resets", to: "password_resets#update"
  
  
  resources :users, only: [:new, :create, :edit, :update, :index]
  namespace :admin do
    get "meetings/show"
    get "dashboard/index"
    get "dashboard", to: "dashboard#index"
    get 'api/startlist_exists', to: 'starts#exists'
    get 'api/results_exists', to: 'results#exists'
    get 'streams/stats', to: 'streams#stats', defaults: { format: :json }


    resources :streams, only: [] do
      collection do
        get :get_streams
        get :get_stream_endpoints
        get :set_stream_endpoints
        get :active
        post :proxy_castr
      end
      member do
        get :endpoints
      end
    end

    resources :api_credentials
    get 'competitions/autocomplete', to: 'competitions#autocomplete'
    get 'meeting/:id/classimport', to: 'meetings#classimport', as: 'meeting_classimport'
    get 'meeting/:id/horseimport', to: 'meetings#horseimport', as: 'meeting_horseimport'
    
    delete 'import/delete', to: 'imports#destroy', as: 'delete_import'
    resources :competitions, only: [:index, :new, :create, :edit, :update, :show]
    resources :competitions, path: "competitions" do
      member do
        get :import_equipe
        get :import_hippo

      end
    end
    
    resources :meetings, only: [:show] do
      resources :starts, only: [:create]
      resources :results, only: [:create]
      
      member do
        get :videos
        post :start_stream
        post :stop_stream

    
        get 'antmedia',             to: 'antmedia_streams#index',          as: :antmedia
        post 'antmedia/import',     to: 'antmedia_streams#import_antmedia', as: :import_antmedia
        post 'antmedia',            to: 'antmedia_streams#create',         as: :antmedia_create
        patch 'antmedia/:stream_id', to: 'antmedia_streams#update',        as: :antmedia_update
        delete 'antmedia/:stream_id', to: 'antmedia_streams#destroy',      as: :antmedia_destroy
        
      end
    end
    #get 'meeting/:id', to: 'meetings#show', as: 'meeting'
  end

  get '/admin/competitions/new', to: 'admin/competitions#new', as: 'new_competition'
  get '/admin/import/equipe', to: 'admin/imports#equipe', as: 'import_equipe'
  get '/admin/import/hippodata', to: 'admin/imports#hippodata', as: 'import_hippo'
  get '/admin/competitions/search', to: 'admin/competitions#search', as: :search_competitions
end
