module RedsunSearchHelper

  def facet(name, results, attribute = nil,  partial = "facet")
    render :partial => partial, :locals => { :facet => name, :results => results, :attribute => attribute }
  end

  def highlighter_for(field, hit, record, strip_tags = false)
    if hit.highlights(field).present?
      sanitized_field = strip_tags == true ? strip_tags(hit.highlights(field)) : hit.highlights(field)
      sanitized_field.collect { |segment| segment.format { |word| "<span class='redsun-highlight'>#{word}</span>" }}.join(" ").html_safe
    else
      if record.respond_to?(field.to_sym)
        strip_tags == true ? strip_tags(record.send(field)) : record.send(field)
      end
    end
  end

end