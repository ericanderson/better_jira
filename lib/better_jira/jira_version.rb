module BetterJira
  class JiraVersion
    attr_accessor :archived, :id, :name, :release_date, :released, :sequence
    
    def self.convert_from_soap(s)
      if (s.is_a? SOAP::Mapping::Object) then
        ret = JiraVersion.new
        ret.archived = s.archived
        ret.id = s.id
        ret.name = s.name
        ret.release_date = s.releaseDate
        ret.released = s.released
        ret.sequence = s.sequence
        ret
      end
    end

  end
end # module BetterJira