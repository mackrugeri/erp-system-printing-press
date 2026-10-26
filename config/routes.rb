Rails.application.routes.draw do
  resources :accounts
  resources :journal_entries do
    collection do
      post :add_row
    end
  end
  resources :fiscal_periods do
    member do
      post :close
    end
  end

  resources :items
  resources :item_categories, only: [:index, :create, :destroy]
  resources :productions, only: [:index, :show, :new, :create]
  resources :cash_tallies, only: [:index, :new, :create, :show]
  resources :payments, only: [:index, :new, :create, :show]
  resources :fiscal_closings, only: [:new, :create]
  resources :warehouses
  resources :stock_transactions
  resources :invoices
  resources :purchase_bills
  resources :contacts

  resources :reports, only: [] do
    collection do
      get :trial_balance
      get :profit_and_loss
      get :balance_sheet
    end
  end


  get 'reports/trial_balance', to: 'reports#trial_balance'
  get 'reports/p_and_l', to: 'reports#profit_and_loss'
  get 'reports/balance_sheet', to: 'reports#balance_sheet'
  root 'dashboard#index'

end