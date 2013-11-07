module RedsunSearchHelper

  def facet(name, results, attribute = nil, ar_object = nil, partial = "facet")
    render :partial => partial, :locals => { :facet => name, :results => results, :attribute => attribute, :ar_object => ar_object }
  end

  def highlighter_for(field, hit, record)
    if hit.highlights(field.to_sym).collect { |segment| segment.format { |word| "<span class='highlight'>#{word}</span>" }}.present?
      hit.highlights(field.to_sym).collect { |segment| segment.format { |word| "<span class='highlight'>#{word}</span>" }}.join(" ").html_safe
    else
      record.send field.to_sym
    end
  end

end