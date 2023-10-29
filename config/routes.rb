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
      get 'attendances/edit_month_approval' #所属長承認の編集
      patch 'attendances/update_month_approval' #所属長承認の更新
      # 確認のshowページ
      get 'verifacation'
    end
  resources :attendances, only: [:update] do
      member do
        # 残業申請モーダル
        get 'edit_overtime_request'
        patch 'update_overtime_request' 
        # 残業申請お知らせモーダル
        get 'edit_overtime_notice'
        patch 'update_overtime_notice'
        # 残業申請確認モーダル
        get 'show_overtime_verifacation'
        # 勤怠変更お知らせモーダル
        get 'edit_one_month_notice'
        patch 'update_one_month_notice'
        #１ヶ月承認モーダル
        get 'edit_month_approval_notice'
        patch 'update_month_approval_notice'
         # 勤怠ログ
        get 'log'
      end
  end
  end
end
