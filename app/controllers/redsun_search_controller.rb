# :nodoc:
class RedsunSearchController < ApplicationController
  unloadable

  before_action :find_optional_project
  before_action :set_search_form


  def index
    searchstring = params[:search_form][:searchstring] || ''

    # Redirect to Issue if ticket ID is entered
    if searchstring.match(/^\s*[#]?(\d+).*$/) && Issue.visible.find_by_id($1.to_i)
      redirect_to controller: 'issues', action: 'show', id: $1.to_i
      return
    end

    allowed_projects = []
    allowed_issues = []
    allowed_wikis = []

    if @project && search_scope == 'project'
      params[:search_form][:project_id] = @project.id
      projects = @project.self_and_descendants.all
      allowed_projects << projects.collect { |p| p.id if User.current.allowed_to?(:view_project, p) }.compact
      allowed_issues << projects.collect { |project| project.id if User.current.allowed_to?(:view_issues, project) }.compact
      allowed_wikis << projects.collect { |project| project.id if User.current.allowed_to?(:view_wiki_pages, @project) }.compact
    elsif search_scope == 'my_projects'
      projects = User.current.memberships.collect(&:project).compact.uniq
      allowed_projects << projects.collect(&:id)
      allowed_issues << projects.collect { |project| project.id if User.current.allowed_to?(:view_issues, project) }.compact
      allowed_wikis << projects.collect { |project| project.id if User.current.allowed_to?(:view_wiki_pages, project) }.compact
    # Search all projects
    else
      projects = Project.all
      allowed_projects << projects.collect { |p| p.id if User.current.allowed_to?(:view_project, p) }.compact
      allowed_issues << projects.collect { |p| p.id if User.current.allowed_to?(:view_issues, p) }.compact
      allowed_wikis << projects.collect { |p| p.id if User.current.allowed_to?(:view_wiki_pages, p) }.compact
    end

    allowed_projects = allowed_projects.push(0)
    allowed_issues = allowed_issues.push(0)
    allowed_wikis = allowed_wikis.push(0)

    @search = Sunspot.search([Project, Issue, WikiPage, Journal, Attachment, News]) do
      fulltext searchstring do
        highlight :description
        highlight :summary
        highlight :comments
        highlight :subject
        highlight :wiki_content
        highlight :name
        highlight :notes
        highlight :id
        highlight :title
        highlight :filename
      end

      any_of do
        all_of do
          with :class, Issue
          with(:project_id).any_of allowed_issues.flatten
          with(:is_private, false)
        end

        all_of do
          with :class, WikiPage
          with(:project_id).any_of allowed_wikis.flatten
        end

        all_of do
          with :class, Project
          with(:project_id).any_of allowed_projects.flatten
        end

        all_of do
          with :class, Journal
          with(:project_id).any_of allowed_issues.flatten
          with(:journalized_type, 'Issue')
          with(:is_private, false)
        end

        all_of do
          with :class, Attachment
          with(:project_id).any_of allowed_projects.flatten
        end
        
        all_of do
          with :class, News
          with(:project_id).any_of allowed_projects.flatten
        end

      end

      %w(author_id
         project_name
         assigned_to_id
         priority_id
         tracker_id
         status_id
         category_id
         filetype
         class_name).each do |easy_facet|
           facet_filter = if params[:search_form].key?(easy_facet)
                            with(easy_facet).any_of(params[:search_form][easy_facet])
                          else
                            all_of {} # not necessary for searching, but object is needed to set exclude option
                          end
        facet easy_facet, minimum_count: 0, exclude: facet_filter
      end
      
      # Class
      class_facet_filter = if params[:search_form].key?(:class_name)
                             with(:class_name).any_of(params[:search_form][:class_name])
                           else
                             all_of {} # not necessary for searching, but object is needed to set exclude option
                           end
      facet :class_name, minimum_count: 0, exclude: class_facet_filter
      
      %w(created_on updated_on).each do |date_facet|
        if params[:search_form].present? && params[:search_form][date_facet].present?
          date_range = date_conditions.collect { |c| c[:date] if (c[:name].to_s == params[:search_form][date_facet.to_sym]) }.compact.first
          with(date_facet).greater_than(date_range) unless date_range.nil?
        end
      end

      # Pagination
      paginate(page: params[:page], per_page: 15)

      # Created on facet
      facet :created_on do
        date_conditions.each do |condition|
          row(condition[:name].to_s) do
            with(:created_on).greater_than condition[:date]
          end
        end
      end

      # Updated on facet
      facet :updated_on do
        date_conditions.each do |condition|
          row(condition[:name].to_s) do
            with(:updated_on).greater_than condition[:date]
          end
        end
      end

      order_by(sort_field.to_sym, sort_order.downcase.to_sym)
      order_by(:score, :desc)
      spellcheck(count: 3)
    end
    @searchstring = searchstring
    redirect_if_neccessary

  rescue Errno::ECONNREFUSED
    render 'connection_refused'
  rescue RSolr::Error::Http
    render 'connection_refused'
  end

  protected

  def set_search_form
    params[:search_form] = {} unless params[:search_form].present?
    @scope = params[:search_form][:scope] || 'all_projects'
    params[:search_form][:class_name] ||= []
    params[:search_form][:class_name] = [] if params[:search_form][:class_name].blank?
    @sort_field = sort_field
    @sort_order = sort_order
    @scope_selector = [[l(:label_my_projects), 'my_projects'], [l(:label_project_all), 'all_projects']]
    @redsun_path = @project.present? ? redsun_project_search_path(@project) : redsun_search_path
    @scope_selector.push([l(:label_and_its_subprojects, @project.name), 'project']) if @project
  end

  def date_conditions
    conditions = []
    conditions << { name: :last_7_days,   date: (Time.now - 7.day)     }
    conditions << { name: :last_month,    date: (Time.now - 31.day)    }
    conditions << { name: :last_3_months, date: (Time.now - 3.months)  }
    conditions << { name: :last_6_months, date: (Time.now - 6.months)  }
    conditions << { name: :older,         date: (Time.now - 12.months) }
    conditions
  end

  private
  
  def redirect_if_neccessary
    # No need to redirect
    return true if @search.total > 0 
    # Class name was select but no result was found
    if params[:search_form].key?(:class_name) && params[:search_form][:class_name].any? && @search.facet(:class_name).rows.map(&:count).count > 0
      flash_message = I18n.translate("redsun.redirect_for_missing_results", 
                                     class_name: I18n.translate("redsun.#{params[:search_form][:class_name].try(:first).try(:downcase)}") )
      redirect_to redsun_search_url(search_form: params[:search_form].except(:class_name)), notice: flash_message
    else
      true
    end
  end

  def search_scope
    params[:search_form][:scope] || 'all_projects'
  end

  def sort_order
    return params[:search_form][:sort_order] if Issue::SORT_ORDER.collect(&:first).include?(params[:search_form][:sort_order])
    'DESC'
  end
  
  def sort_field
    return params[:search_form][:sort_field] if Issue::SORT_FIELDS.include?(params[:search_form][:sort_field])
    'score'
  end

  def find_optional_project
    return true unless (params[:id] || params[:project_id])
    if params[:id] && controller.controller_name == "projects"
      @project = Project.find(params[:id])
    else
      @project = Project.find(params[:project_id])
    end
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
