module BetterJira
  module Exceptions
    def self.wrap_soap
      begin
        yield
      rescue SOAP::FaultError
        case $!.faultstring.data
        when "com.atlassian.jira.rpc.exception.RemotePermissionException: This issue does not exist or you don't have permission to view it."
          raise NoSuchIssueException, "This issue does not exist or you don't have permission to view it."
        end
      end
    end # def wrap_soap
    
    class JiraException < RuntimeError
    end
    
    class NoSuchIssueException < JiraException
      
    end
    
  end # module Exceptions
end # module BetterJira