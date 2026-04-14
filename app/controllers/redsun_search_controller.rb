# :nodoc:
class RedsunSearchController < ApplicationController
  before_action :find_optional_project
  before_action :set_search_form

  def index
    searchstring = search_params[:searchstring] || ''


    # Redirect to Issue if ticket ID is entered
    if searchstring.match(/^\s*\#?(\d+).*$/) && Issue.visible.find_by_id(::Regexp.last_match(1).to_i)
      redirect_to controller: 'issues', action: 'show', id: ::Regexp.last_match(1).to_i
      return
    end

    allowed_projects = []
    allowed_issues = []
    allowed_wikis = []
    if @project && search_params[:scope] == 'project'
      projects = @project.self_and_descendants.all
      allowed_projects << projects.collect { |project| project.id if User.current.allowed_to?(:view_project, project) }.compact
      allowed_issues << projects.collect { |project| project.id if User.current.allowed_to?(:view_issues, project) }.compact
      allowed_wikis << projects.collect { |project| project.id if User.current.allowed_to?(:view_wiki_pages, project) }.compact
    else
      projects = Project.includes(:enabled_modules).select(:id, :status, :is_public)
      projects.each do |project|
        allowed_projects << project.id if User.current.allowed_to?(:view_project, project)
        allowed_issues << project.id if User.current.allowed_to?(:view_issues, project)
        allowed_wikis << project.id if User.current.allowed_to?(:view_wiki_pages, project)
      end
    end
    allowed_projects = allowed_projects.compact.push(0)
    allowed_issues = allowed_issues.compact.push(0)
    allowed_wikis = allowed_wikis.compact.push(0)

    @search = Sunspot.search([Project, Issue, WikiPage, Journal, Attachment, News]) do
      adjust_solr_params do |p|
        p['hl']           = 'on'
        p['hl.fl']        = 'subject_text description_text' # explizite Felder
        p['hl.requireFieldMatch'] = 'false'  # nur highlighten, wenn Feld im Query explizit vorkam
        p['hl.fragsize']  = 150
        p['hl.method'] = 'unified'
        p['hl.q'] = searchstring
      end

      fuzzy_search_string = searchstring
      if fuzzy_search_string.length < 8
        fuzzy_search_string += "~1"
      else
        fuzzy_search_string += "~2"
      end
      fulltext "#{fuzzy_search_string}" do
        boost_fields title: 10.0, subject: 10.0
        unless searchstring.blank?
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

      %w[author_id
         project_name
         assigned_to_id
         filetype
         class_name
         tags
         ].each do |easy_facet|
        facet_filter = if params[:search_form].key?(easy_facet)
                         with(easy_facet).any_of(params[:search_form][easy_facet])
                       else
                         all_of {} # not necessary for searching, but object is needed to set exclude option
                       end
        if %w[project_name].include?(easy_facet)
          facet easy_facet, minimum_count: 1, exclude: facet_filter, limit: -1
        else
          facet easy_facet, minimum_count: 1, exclude: facet_filter
        end
      end

      # Boolean
      %w[is_closed
         active].each do |boolean_facet|
        boolean_facet_filter = if params[:search_form].key?(boolean_facet)
                                 if params[:search_form][boolean_facet].length == 2
                                   with(boolean_facet).any_of(params[:search_form][boolean_facet].map{|val| ActiveModel::Type::Boolean.new.cast(val)})
                                 else
                                   with(boolean_facet).all_of(params[:search_form][boolean_facet].map{|val| ActiveModel::Type::Boolean.new.cast(val)})
                                 end
                                else
                                  all_of {} # not necessary for searching, but object is needed to set exclude option
                                end
        facet boolean_facet, minimum_count: 2, exclude: boolean_facet_filter
      end

      # Class
      class_facet_filter = if params[:search_form].key?(:class_name)
                             with(:class_name).any_of(params[:search_form][:class_name])
                           else
                             all_of {} # not necessary for searching, but object is needed to set exclude option
                           end
      facet :class_name, minimum_count: 1, exclude: class_facet_filter

      %w[created_on updated_on].each do |date_facet|
        next unless params[:search_form].present? && params[:search_form][date_facet].present?

        date_range = date_conditions.collect do |c|
          c[:date] if c[:name].to_s == params[:search_form][date_facet.to_sym]
        end.compact.first
        with(date_facet).greater_than(date_range) unless date_range.nil?
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
    params[:search_form].permit!
    params[:search_form][:class_name] ||= []
    params[:search_form][:class_name] = [] if params[:search_form][:class_name].blank?
    @sort_field = sort_field
    @sort_order = sort_order
  end

  def date_conditions
    conditions = []
    conditions << { name: :last_7_days,   date: (Time.current - 7.day)     }
    conditions << { name: :last_month,    date: (Time.current - 1.month)    }
    conditions << { name: :last_3_months, date: (Time.current - 3.months)  }
    conditions << { name: :last_6_months, date: (Time.current - 6.months)  }
    conditions << { name: :older,         date: (Time.current - 12.months) }
    conditions
  end

  private

  def redirect_if_neccessary
    # No need to redirect
    return true if @search.total > 0

    # Class name was select but no result was found
    if params[:search_form].key?(:class_name) && params[:search_form][:class_name].any? && @search.facet(:class_name).rows.map(&:count).count > 0
      flash_message = I18n.translate('redsun.redirect_for_missing_results',
                                     class_name: I18n.translate("redsun.#{params[:search_form][:class_name].try(:first).try(:downcase)}"))
      redirect_to redsun_search_url(search_form: params[:search_form].except(:class_name)), notice: flash_message
    else
      true
    end
  end

  def sort_order
    if Issue::SORT_ORDER.collect(&:first).include?(params[:search_form][:sort_order])
      return params[:search_form][:sort_order]
    end
    'DESC'
  end

  def sort_field
    return params[:search_form][:sort_field] if Issue::SORT_FIELDS.include?(params[:search_form][:sort_field])
    'updated_on'
  end

  def find_optional_project
    return true unless params[:id] || params[:project_id]

    @project = if params[:id] && controller.controller_name == 'projects'
                 Project.find(params[:id])
               else
                 Project.find(params[:project_id])
               end
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def search_params
    params.require(:search_form).permit!
  end
end
