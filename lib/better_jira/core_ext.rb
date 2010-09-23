class Hash
  def symbolize_keys!
    replace(inject({}) { |h,(k,v)| h[k.to_sym] = v; h })
  end
  
  def require_keys!(*keys)
    missing = []
    
    keys.each do |key|
      missing << key unless self.has_key? key
    end

    raise "Required keys: #{missing.join(", ")}" unless missing.empty?
  end
end
