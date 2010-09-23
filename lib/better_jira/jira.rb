require 'soap/wsdlDriver'
require 'better_jira/utils'

module BetterJira

  class Jira
    def initialize(jira_url, trust_ca = nil) 
      @jira_url = jira_url
      @soap = SOAP::WSDLDriverFactory.new(@jira_url + "/rpc/soap/jirasoapservice-v2?wsdl").create_rpc_driver
    
      @client = HTTPClient.new
      @client.ssl_config.set_trust_ca(trust_ca) unless trust_ca.nil?
    end
    
    # Login to the jira instance
    #
    # @param [String] username your username
    # @param [String] password your password
    #
    # @raise if login fails
    def login(username, password)
      @token = @soap.login(JIRA_USERNAME, JIRA_PASSWORD)
    
      destination = '/success'
      res = @client.post("#{@jira_url}/secure/Dashboard.jspa", {
        'os_username' => username,
        'os_password' => password,
        'os_destination' => destination
      })
      raise "Login Fail!" if res.status != 302 || (res.header['Location'] && res.header['Location'].first[-destination.length, destination.length] != destination)
    end

    # Retrieves all the fields available for edit on the particular issue key
    #
    # @param [String] key the issue key to check (ie: TEST-100)
    # @return [Hash] a hash of jira field id to name
    def fields_for_edit(key)
      BetterJira::array_of_remote_fields_to_map(@soap.getFieldsForEdit(@token, key))
    end

    # Iterates over all the issues in a filter, passing each JiraIssue into the block
    #
    # @param [Integer] filter_id the filter to load
    # @param [Hash] options the options to use when iterating
    # @option options [Integer] :batch_size (50) the number of issues to retrieve at a time
    # @option options [Integer] :exclude_if_in_filter (nil) a filter to use as an exclude list if present
    # @yield a block for iterating over the list
    # @yieldparam [JiraIssue] issue
    def each_issue_from_filter(filter_id, options ={}, &block)
      options[:batch_size] ||= 50
    
      exclude_issues = []
    
      if (options[:exclude_if_in_filter]) then
        each_issue_from_filter(options[:exclude_if_in_filter]) { |issue|
          exclude_issues << issue[:key]
        }
      end

      offset = 0
      while( (issues = @soap.getIssuesFromFilterWithLimit(@token, filter_id, offset, options[:batch_size])) != nil) 
        break if offset >= @soap.getIssueCountForFilter(@token, filter_id) 
        offset += issues.length
      
        issues.each {|issue|
          issue = JiraIssue.new(issue, self)
          block.call(issue) unless exclude_issues.include?(issue[:key])
        }
      end
    end
    
    def versions_for_project(project_key)
      @soap.getVersions(@token, project_key)
    end
  
    def update_issue(key, remote_field_changes)
      @soap.updateIssue(@token, key, remote_field_changes)
    end
  
    def convert_custom_field_value_to_happy_jira_time(value)
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
        end
      end
    end
  
    def progress_workflow(key, workflow_action_id, custom_field_values, opts = {})
      puts "Shit passed in" if JIRA_DEBUG
      puts "==============" if JIRA_DEBUG
      p custom_field_values if JIRA_DEBUG
      puts "" if JIRA_DEBUG
    
    
    
      cfvs = []
      
      unless @client.nil?
        res = @client.get("#{@jira_url}/si/jira.issueviews:issue-xml/#{key}/#{key}.xml")
        puts res.content if JIRA_DEBUG
        match = res.content.match(/<timeestimate seconds="(.*?)">(.*?)<\/timeestimate>/)
        time_estimate = "#{match[1].to_i/60}" unless match.nil?
      end
    
    
      issue = get_issue(key)
      fields = fields_for_action(key, workflow_action_id)
    
      puts "Issue" if JIRA_DEBUG
      p issue if JIRA_DEBUG
      puts "" if JIRA_DEBUG
    
      moronic_map = {
        'issuetype' => 'type',
        'versions' => 'affectsVersions'
      }
        puts "Fields" if JIRA_DEBUG
        puts "======" if JIRA_DEBUG
      fields.each {|f|

        p f if JIRA_DEBUG
        real_field_name = moronic_map[f['id']] ? moronic_map[f['id']] : f['id']
      
        if (real_field_name != '' && custom_field_values[real_field_name.to_sym] != nil)
          value = custom_field_values[real_field_name.to_sym]
        elsif (real_field_name != '' && custom_field_values[real_field_name] != nil)
          value = custom_field_values[real_field_name]
        elsif (real_field_name == 'timetracking') then
          value = time_estimate
        elsif (real_field_name =~ /customfield_/) then
          q = issue.customFieldValues.find { |c| c.customfieldId == real_field_name }
          value = q.values unless q.nil?
        else
          value = nil
          value = issue.send('[]', real_field_name) if not real_field_name.empty?
        end
      
        value = convert_custom_field_value_to_happy_jira_time(value)
      
        puts "" if JIRA_DEBUG
        p value if JIRA_DEBUG
        puts "" if JIRA_DEBUG
      
        cfvs << {:id => f['id'], :values => value}
      }
    
      puts "Output!" if JIRA_DEBUG
      puts "=======" if JIRA_DEBUG
      p cfvs if JIRA_DEBUG
    
    
    
      @soap.progressWorkflowAction(@token, key, workflow_action_id, cfvs)
    end

    def add_comment(key, comment, options={})
      options[:body] = comment if options[:body].nil?
    
      @soap.addComment(@token, key, options)
    end
  
    def available_actions(key)
      @soap.getAvailableActions(@token, key)
    end
  
    def get_issue(key)
      @soap.getIssue(@token, key)
    end
  
    def [](key)
      JiraIssue.new(get_issue(key), self)
    end
  
    def fields_for_action(key, action_id)
      @soap.getFieldsForAction(@token, key, action_id)
    end
  
    def map_version_fields(project, fields, cur_depth = 0, versions = nil)
      versions = versions_for_project(project)
    
      if (cur_depth == 0 && Array === fields) then
        fields.map { |q|
          map_version_fields(project, q, cur_depth + 1, versions)
        }.flatten
      elsif (Fixnum === fields || Integer === fields)
        [fields.to_s]
      elsif (String === fields)
        versions = versions.select { |version| version.name == fields }
        versions = versions.map { |version| version['id'] }
      end
    end
  end

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
  
    def available_actions
      ret = {}
      @jira.available_actions(self[:key]).each{|q| ret[q['id']] = q['name']}
      ret
    end
  
    def fields_for_action_id(action_id)
      ret = {}
      @jira.fields_for_action(self[:key], action_id).each {|q| ret[q['id']] = q['name']}
      ret
    end
  
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
  end # class Jira
end # module BetterJira
