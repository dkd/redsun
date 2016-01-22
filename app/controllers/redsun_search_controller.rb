# :nodoc:
class RedsunSearchController < ApplicationController
  unloadable

  before_filter :find_optional_project
  before_filter :set_search_form

  def index
    searchstring = params[:search_form][:searchstring] || ''

    # Redirect to Issue if ticket ID is entered
    if searchstring.match(/^#?(\d+)$/) && Issue.visible.find_by_id($1.to_i)
      redirect_to controller: 'issues', action: 'show', id: $1
      return
    end

    allowed_projects = []
    allowed_issues = []
    allowed_wikis = []

    if @project && @scope == 'project'
      params[:search_form][:project_id] = @project.id
      projects = @project.self_and_descendants.all
      allowed_projects << projects.collect { |p| p.id if User.current.allowed_to?(:view_project, p) }.compact
      allowed_issues << projects.collect { |project| project .id if User.current.allowed_to?(:view_issues, project) }.compact
      allowed_wikis << projects.collect { |project| project.id if User.current.allowed_to?(:view_wiki_pages, @project) }.compact
    elsif @scope == 'my_projects'
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

    sort_order = @sort_order
    sort_field = @sort_field

    @search = Sunspot.search([Project, Issue, WikiPage, Journal]) do
      fulltext searchstring do
        highlight :description
        highlight :comments
        highlight :subject
        highlight :wiki_content
        highlight :name
        highlight :notes
        highlight :id
        highlight :title
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
      end

      %w(author_id
         project_name
         assigned_to_id
         status_id
         tracker_id).each do |easy_facet|
        facet easy_facet, minimum_count: 1
        if params.key?(:search_form) && params[:search_form][easy_facet].present?
          with(easy_facet, params[:search_form][easy_facet])
        end
      end

      %w(priority_id
         class_name).each do |easy_facet|
        facet easy_facet, minimum_count: 1
        if params.key?(:search_form) && params[:search_form][easy_facet.to_sym].present?
          with(easy_facet, params[:search_form][easy_facet.to_sym])
        end
      end

      %w(created_on updated_on).each do |date_facet|
        if params[:search_form].present? && params[:search_form][date_facet].present?
          date_range = date_conditions.collect { |c| c[:date] if (c[:name].to_s == params[:search_form][date_facet.to_sym]) }.compact.first
          with(date_facet).greater_than(date_range) unless date_range.nil?
        end
      end

      if params.key?(:search_form) && params[:search_form][:active].present?
        with(:active, (params[:search_form][:active] == 'true' ? true : false))
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
    end
    @searchstring = searchstring

  rescue Errno::ECONNREFUSED
    render 'connection_refused'
  rescue RSolr::Error::Http
    render 'connection_refused'
  end

  protected

  def set_search_form
    params[:search_form] = {} unless params[:search_form].present?

    if params[:project_id].present?
      @project = Project.find(params[:project_id])
    elsif params[:search_form][:project_id].present?
      @project = Project.find(params[:search_form][:project_id])
    end

    # Reset facets if search button is pressed
    if params[:commit].present?
      [:author_id,
       :status_id,
       :tracker_id,
       :priority_id,
       :created_on,
       :updated_on,
       :class_name,
       :active].each do |facet|
        params[:search_form].delete(facet) if params[:search_form][facet].present?
      end
    end

    if params[:search_form].present? && Issue::SORT_FIELDS.include?(params[:search_form][:sort_field])
      @sort_field = params[:search_form][:sort_field]
    else
      @sort_field = 'score'
    end

    if params[:search_form].present? && Issue::SORT_ORDER.collect(&:first).include?(params[:search_form][:sort_order])
      @sort_order = params[:search_form][:sort_order]
    else
      @sort_order = 'DESC'
    end

    @scope = params[:search_form][:scope] || 'all_projects'
    @scope_selector = [[l(:label_my_projects), 'my_projects'], [l(:label_project_all), 'all_projects']]
    @redsun_path = @project.present? ? redsun_project_search_path(project_id: @project.id) : redsun_search_path
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

  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
