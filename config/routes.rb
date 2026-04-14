get 'redsun', to: 'redsun_search#index', as: 'redsun_search'
resources :projects do
  get 'redsun', to: 'redsun_search#index', as: 'redsun_search'
end