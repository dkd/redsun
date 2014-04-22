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

    @allowed_issue_trackers = []
    @allowed_wikis = []
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
      @allowed_issue_trackers << @project.id if User.current.allowed_to?(:view_issues, @project)
      @allowed_wikis << @project.id if User.current.allowed_to?(:view_wiki_pages, @project)
    else
      @allowed_issue_trackers = User.current.projects.collect { |project| project.id if User.current.allowed_to?(:view_issues, project) }.compact
      @allowed_wikis << User.current.projects.collect { |project| project.id if User.current.allowed_to?(:view_wiki_pages, project) }.compact
    end

    @search = Sunspot.search(Issue, WikiPage) do |query|
      query.fulltext searchstring do
        highlight :description
        highlight :subject
        highlight :wiki_content
      end
      
      if @project.present?
        query.with(:project_id, @project.id)
      end

      %w(author_id assigned_to_id status_id tracker_id priority_id class_name).each do |easy_facet|
        query.facet easy_facet, :minimum_count => 2
        if params.has_key?(:search_form) && params[:search_form][easy_facet].present?
          query.with(easy_facet, params[:search_form][easy_facet])
        end
      end
      
      conditions = date_conditions(query, :created_on)
      
      %w(created_on updated_on).each do |date_facet|
        if params[:search_form].present? && params[:search_form][date_facet.to_sym].present?
          date_range = conditions.collect { |c| c[:date] if (c[:name].to_s == params[:search_form][date_facet.to_sym]) }.compact.first
          query.with(date_facet.to_sym).greater_than(date_range) unless date_range.nil?
        end
      end

      # Pagination
      query.paginate(:page =>  params[:page], :per_page => 15)
      
      # Created on facet
      
      query.facet :created_on do
        conditions.each do |condition|
          row(condition[:name].to_s) do
            with(:created_on).greater_than condition[:date]
          end
          #row(condition[:name].to_s) do
          #  with(:updated_on).greater_than condition[:date]
          #end
        end
      end

      query.order_by(@sort_field.to_sym, @sort_order.downcase.to_sym)
      query.order_by(:score, :desc)

    end
    @searchstring = searchstring

    #@search = @search.results.select {|r| @allowed_issue_trackers.include? r.project_id}
    @authorized_search = @search.results.select {|r| @allowed_issue_trackers.include?(r.project_id)|| @allowed_wikis.include?(r.project_id)}
    #rescue
    #  render :text => "Oh no, the Solr server is gone?!", :layout => true
    #end
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

  def date_conditions(query, field)
    conditions = []
    conditions << {:name => :last_7_days, :date => (Time.now - 7.day)}
    conditions << {:name => :last_month, :date => (Time.now - 31.day)}
    conditions << {:name => :last_3_months, :date => (Time.now - 3.months)}
    conditions << {:name => :last_6_months, :date => (Time.now - 6.months)}
    conditions << {:name => :last_12_months, :date => (Time.now - 12.months)}
    conditions
  end

end
