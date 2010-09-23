module BetterJira
  class JiraIssue
    attr_reader :custom_fields
  
    FIELDS = [:summary, :description]
  
    def initialize(soap_jira_issue, jira)
      @soap_jira_issue = soap_jira_issue
      @jira = jira
      @changes = []
      @custom_fields = {}
      @soap_jira_issue.customFieldValues.each { |cf|
        @custom_fields[cf.customfieldId] = cf.values
      }
    end

    def update_fields(fields)
      fields[:fixVersions] = fields[:fix_versions] if fields.has_key? :fix_versions
      fields[:versions] = fields[:affects_versions] if fields.has_key? :affects_versions
    
      fields.each {|k,v|
        case k
          when :fixVersions then
            fields[k] = @jira.map_version_fields(self[:project], v)
          when :versions
            fields[k] = @jira.map_version_fields(self[:project], v)
        end
      }
    
    
      fields = fields.map {|k,v|
        {:id => k, :values => BetterJira::convert_custom_field_value_to_happy_jira_time(v)}
      }
      @jira.update_issue(self[:key], fields)
      initialize(@jira.get_issue(self[:key]), @jira)
    end
    
    def field_value(key)
      r = self[key]
      r = r.first unless (r.nil?)
      return r
    end
  
    def field_values(key)
      self[key]
    end
  
    def [](key)
      if (key.to_s =~ /customfield_/) then
        BetterJira::custom_field_values(@soap_jira_issue, key.to_s)
      elsif (Symbol === key) then
        begin
          @soap_jira_issue.send "[]", key.to_s
        rescue NoMethodError => e
          nil
        end
      else
      
      end
    end
  
    def field_as_date_time(key)
      BetterJira::custom_field_value_as_date_time(@soap_jira_issue, key.to_s)
    end
  
    # Returns a list of available actions for this issue
    def available_actions
      ret = {}
      @jira.available_actions(self[:key]).each{|q| ret[q['id']] = q['name']}
      ret
    end
    
    # Returns a list of fields for a particular action_id
    def fields_for_action_id(action_id)
      ret = {}
      @jira.fields_for_action(self[:key], action_id).each {|q| ret[q['id']] = q['name']}
      ret
    end
  
    # Adds a comment to the issue
    def add_comment(comment, options={})
      @jira.add_comment(self[:key], comment, options)
    end
  
    def fields_for_action_name(action_name)
      action = available_actions.find {|k, v| v == action_name}
      fields_for_action_id(action[0])
    end
  
  
    def fields_for_edit
      BetterJira::array_of_remote_fields_to_map(@jira.get_fields_for_edit(self[:key]))
    end
  
    def progress_workflow(workflow_action_id, custom_field_values, opts = {})
      @jira.progress_workflow(self[:key], workflow_action_id, custom_field_values, opts)
    end
  end # class JiraIssue
end