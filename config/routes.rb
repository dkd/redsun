# map.with_options :path_prefix => 'projects/:project_id' do |p|
#    p.connect 'redsun/:action', :controller => "sunspot_search", :action => :index
# end

scope "projects/:project_id" do
  match "redsun/:action", :to => "redsun_search#index", :via => :get, :as => "redsun_search"
end