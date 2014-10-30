require 'yaml'

module N42translation
  class Strings
    def self.createStrings(yaml)
      return Array[yaml.map{|key,value| ["\"#{key}\" = \"#{value}\";"] }]
    end
  end
end