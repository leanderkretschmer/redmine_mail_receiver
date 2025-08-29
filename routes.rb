Rails.application.routes.draw do
  resources :mail_receiver_settings, only: [:edit, :update] do
    collection do
      post :manual_import
      post :clear_log
    end
  end
end
