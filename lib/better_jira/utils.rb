module BetterJira
  def self.custom_field_values(issue, field) 
    issue.customFieldValues.each { |cfv|
      if (cfv.customfieldId == field) then
        return cfv.values
      end
    }
  
    return nil
  end

  def self.custom_field_value(issue, field, &block) 
    if (block == nil) then
      block = Proc.new {|x| x}
    end
  
    values = custom_field_values(issue, field)
  
    return block.call(values.first) if (values != nil)

    return nil
  end

  def self.custom_field_value_as_date_time(issue, field)
    custom_field_value(issue, field) { |x| DateTime.parse(x, true) }
  end
  
  # Converts an array of RemoteFields into a map of id => name
  #
  # @return [Hash] the converted map
  def self.array_of_remote_fields_to_map(remote_fields)
    ret = {}
    remote_fields.each{|q| ret[q['id']] = q['name']}
    ret
  end
  
  def self.simple_soap_mapping(a)
    ret = {}
    a.each{|q| ret[q['id']] = q['name']}
    ret
  end
  
  def self.convert_custom_field_value_to_happy_jira_time(value)
    if (value != nil) then
      if (Array === value) then
        value = value.map { |x| 
          q = nil
          q = x if String === x
          q = x['id'] if SOAP::Mapping::Object === x
          q
        }
      elsif (SOAP::Mapping::Object === value) then
        value = [value['id']]
      elsif (String === value) then
        value = [value]
      elsif (DateTime === value) then
        value = [value.strftime('%d/%b/%y')]
      else
        value = [value.to_s]
      end
    end
  end
end