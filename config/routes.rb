Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # 图片代理路由
  get "proxy_image", to: "proxy#image", as: :proxy_image
  delete "proxy_image/clear_cache", to: "proxy#clear_cache", as: :clear_proxy_cache

  # Defines the root path route ("/")
  resources :topics do
    member do
      post :refresh
    end
  end

  root "topics#index"
end
