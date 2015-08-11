get 'redsun', to: 'redsun_search#index', as: 'redsun_search'
scope 'projects/:project_id' do
  get 'redsun/:action', to: 'redsun_search#index', as: 'redsun_project_search'
end
