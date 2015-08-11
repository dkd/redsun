# :nodoc
module RedsunSearchHelper
  def facet(name, results, attribute = nil, partial = 'facet')
    render partial: partial, locals: { facet: name, results: results, attribute: attribute }
  end

  def highlighter_for(field, hit, record)
    if hit.highlights(field).present?
      hit.highlights(field).collect { |segment| segment.format { |word| "<span class='redsun-highlight'>#{word}</span>" } }.join(' ').html_safe
    else
      record.send(field) if record.respond_to?(field.to_sym)
    end
  end
end
