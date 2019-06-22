Rails.application.routes.draw do
  get 'post_categories/new'
  get 'post_categories/create'
  get 'post_categories/destroy'
  root to: 'static_pages#home'
  get 'home', to: "static_pages#home"
  get 'about', to: "static_pages#about"
  get 'login', to: "sessions#new"
  post 'login', to: "sessions#create"
  get 'logout', to: "sessions#destroy"
  resources :users
  resources :posts
  resources :comments, only: [:create, :destroy, :update]
  resources :categories
  resources :post_categories
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
