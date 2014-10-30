require 'thor'
require 'yaml'
require 'n42translation/xml'
require 'n42translation/strings'

module N42translation
  class CLI < Thor
    desc "xml <yamlfile> <outputfile>", "converts the content of the yaml file to a iOS strings file"
    def xml(inputfile, outputfile)
      yaml = load_yaml(inputfile)
      fileContent = N42translation::XML.createXML(join_hash_keys(yaml)).target!
      save_with_filename(fileContent, outputfile)
    end

    desc "strings <yamlfile> <outputfile>", "converts the content of the yaml file to a android xml file"
    def strings(inputfile, outputfile)
      yaml = load_yaml(inputfile)
      fileContent = N42translation::Strings.createStrings(join_hash_keys(yaml)).join("\n")
      save_with_filename(fileContent, outputfile)
    end

    private
    def load_yaml(filename)
      return YAML.load_file(filename)
    end

    def save_with_filename(content, filename)
      File.open(filename, 'w') { |file| file.write(content) }
    end
    
    # flatten the hash, ["a" => ["b" => "c"]] becomes [["a", "b"]=>"c"]
    def flat_hash(h,f=[],g={})
      return g.update({ f=>h }) unless h.is_a? Hash
        h.each { |k,r| flat_hash(r,f+[k],g) }
        g
    end

    # flatten and jon the hash keys, [["a", "b"]=>"c"] becomes ["a.b"=>"c"]
    def join_hash_keys(hash)
      Hash[flat_hash(hash).map {|k, v| [k.join("."), v] }]
    end

  end  
end
