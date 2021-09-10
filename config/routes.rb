Rails.application.routes.draw do
  get 'bases/index'

  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  resources :bases
  resources :users do
    collection { post :import }
    collection do
      get 'working'
    end

    member do
      get 'all_user_edit'
      get 'edit_basic_info'
      patch 'update_basic_info'
      patch 'update_index'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month' # この行が追加対象です。
    end
  resources :attendances, only: [:update] do
      member do
        # 残業申請モーダル
        get 'edit_overtime_request'
        patch 'update_overtime_request'  
      end
  end
  end
end
