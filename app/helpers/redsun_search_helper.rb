# :nodoc
module RedsunSearchHelper
  def facet(name, results, attribute = nil, partial = 'facet')
    render partial: partial, locals: { facet: name, results: results, attribute: attribute }
  end
  
  def selected_attr_for(facet, val)
    if params[:search_form] && params[:search_form][facet.to_sym]
      "selected" if params[:search_form][facet.to_sym] == val.to_s
    end
  end

  def highlighter_for(field, hit, record)
    if hit.highlights(field).present?
      hit.highlights(field).collect { |segment| segment.format { |word| "<span class='redsun-highlight'>#{word}</span>" } }.join(' ').html_safe
    else
      truncate(record.send(field).to_s, length: 300) if record.respond_to?(field.to_sym)
    end
  end

  def search2_enabled?
    Setting[:plugin_redmine_redsun]['enable_select2_plugin']
  end

  def issue_coment_number(comment_id)
    journal = Journal.find(comment_id)
    entries = journal.journalized.journals
    index = entries.find_index(journal)
    index + 1
  end

  def issue_comment_path(comment_id)
    journal = Journal.find(comment_id)
    entries = journal.journalized.journals
    index = entries.find_index(journal)
    issue_url(journal.journalized, anchor: "note-#{issue_coment_number(comment_id)}", format: :html)
  end
end
