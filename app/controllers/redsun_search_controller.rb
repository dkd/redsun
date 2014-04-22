class RedsunSearchController < ApplicationController
  unloadable

  before_filter :set_search_form

  def index

    #begin
    if params[:search_form].present? && params[:search_form][:searchstring].present?
      searchstring = params[:search_form][:searchstring]
    else
      searchstring = ""
    end

    allowed_issues = [0]
    allowed_wikis = [0]

    if params[:project_id].present?
      @project = Project.find(params[:project_id])
      allowed_issues << @project.id if User.current.allowed_to?(:view_issues, @project)
      allowed_wikis << @project.id if User.current.allowed_to?(:view_wiki_pages, @project)
    else
      allowed_issues = User.current.projects.collect { |project| project.id if User.current.allowed_to?(:view_issues, project) }.compact
      allowed_wikis << User.current.projects.collect { |project| project.id if User.current.allowed_to?(:view_wiki_pages, project) }.compact
    end
    
    sort_order = @sort_order
    sort_field = @sort_field
    
    @search = Sunspot.search(Issue, WikiPage) do
      fulltext searchstring do
        highlight :description
        highlight :subject
        highlight :wiki_content
      end

      any_of do
        all_of do
          with :class, Issue
          with(:project_id).any_of allowed_issues 
        end
        all_of do
          with :class, WikiPage
          with(:project_id).any_of allowed_wikis
        end
      end

      %w(author_id assigned_to_id status_id tracker_id priority_id class_name).each do |easy_facet|
        facet easy_facet, :minimum_count => 2
        if params.has_key?(:search_form) && params[:search_form][easy_facet].present?
          with(easy_facet, params[:search_form][easy_facet])
        end
      end
      
      conditions = date_conditions(:created_on)
      
      %w(created_on updated_on).each do |date_facet|
        if params[:search_form].present? && params[:search_form][date_facet.to_sym].present?
          date_range = conditions.collect { |c| c[:date] if (c[:name].to_s == params[:search_form][date_facet.to_sym]) }.compact.first
          with(date_facet.to_sym).greater_than(date_range) unless date_range.nil?
        end
      end

      # Pagination
      paginate(:page =>  params[:page], :per_page => 15)
      
      # Created on facet
      
      facet :created_on do
        conditions.each do |condition|
          row(condition[:name].to_s) do
            with(:created_on).greater_than condition[:date]
          end
          #row(condition[:name].to_s) do
          #  with(:updated_on).greater_than condition[:date]
          #end
        end
      end

      order_by(sort_field.to_sym, sort_order.downcase.to_sym)
      order_by(:score, :desc)

    end
    @searchstring = searchstring
  end

  protected

  def set_search_form
    params[:search_form] = {} unless params[:search_form].present?

    if params[:search_form].present? && Issue::SORT_FIELDS.include?(params[:search_form][:sort_field])
      @sort_field = params[:search_form][:sort_field]
    else
      @sort_field = "score"
    end

    if params[:search_form].present? && Issue::SORT_ORDER.collect { |o| o.first }.include?(params[:search_form][:sort_order])
      @sort_order = params[:search_form][:sort_order]
    else
      @sort_order = "DESC"
    end

  end

  def date_conditions(field)
    conditions = []
    conditions << {:name => :last_7_days, :date => (Time.now - 7.day)}
    conditions << {:name => :last_month, :date => (Time.now - 31.day)}
    conditions << {:name => :last_3_months, :date => (Time.now - 3.months)}
    conditions << {:name => :last_6_months, :date => (Time.now - 6.months)}
    conditions << {:name => :older, :date => (Time.now - 12.months)}
    conditions
  end

end
