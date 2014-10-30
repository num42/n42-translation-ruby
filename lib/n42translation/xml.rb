require 'yaml'
require 'builder'


module N42translation
  class XML
    def self.createXML(yaml)
      return yaml_to_xml(yaml)
    end

    private
    def self.yaml_to_xml(yaml)
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct! :xml, :encoding => "utf-8"
      xml.resources do |r|
        yaml.each do |name, value|
          r.string(value ,:name => name)
        end
      end
      return xml
    end
  end
end





