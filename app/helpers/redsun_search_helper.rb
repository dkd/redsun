# :nodoc:
module RedsunSearchHelper
  def facet(name:, results:, attribute: nil, partial: 'facet')
    render partial:, locals: { facet: name, results:, attribute: }
  end

  def selected_attr_for(facet, value)
    search_params = params.dig(:search_form, facet.to_sym)
    return unless search_params && value.to_s.in?(search_params)

    'selected'
  end

  def highlighter_for(field, hit, record)
    if hit.highlights(field).present?
      format_highlights(hit.highlights(field))
    elsif record.respond_to?(field.to_sym)
      truncate(record.send(field).to_s, length: 150)
    end
  end

  def is_project_scope?
    params[:search_form][:scope] == "project"
  end

  def redsun_inactive_badge(record)
    return unless record.present? && !record.active?

    content_tag(:span, class: 'badge redsun-badge redsun-badge-inactive') do
      t('redsun.inactive')
    end
  end

  def select2_enabled?
    Setting[:plugin_redmine_redsun]['enable_select2_plugin']
  end

  def issue_comment_number(comment_id)
    journal = find_journal(comment_id)
    journal.journalized.journals.index(journal) + 1
  end

  def issue_comment_path(comment_id)
    journal = find_journal(comment_id)
    issue_url(
      journal.journalized,
      anchor: "note-#{issue_comment_number(comment_id)}",
      format: :html
    )
  end

  private

  def format_highlights(highlights)
    highlights.collect do |segment|
      segment.format { |word| highlight_word(word) }
    end.join(' ').html_safe
  end

  def highlight_word(word)
    "<span class='redsun-highlight'>#{word}</span>"
  end

  def find_journal(comment_id)
    Journal.find(comment_id)
  end

  def short_search_result_title?(record)
    class_name = record.class.to_s
    params[:search_form].key?(:class_name) && class_name.in?(params[:search_form][:class_name])
 end

end