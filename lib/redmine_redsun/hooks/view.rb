module RedmineRedsun
  module Hooks
    class View < Redmine::Hook::ViewListener
      # JS Calls
      render_on :view_layouts_base_body_bottom,
                partial: 'hooks/view_layouts_base_body_bottom'
    end
  end
end