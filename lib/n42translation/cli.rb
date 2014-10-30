require 'thor'
require 'yaml'
require 'active_support'
require 'n42translation/xml'
require 'n42translation/strings'

module N42translation
  class CLI < Thor
    desc "xml <file_prefix> <outputfile_path>", "converts the content of the yaml file to a iOS strings file"
    def xml(file_prefix, outputfile_path)
      get_languages(file_prefix).each do |lang|
        yaml = load_yaml([file_prefix, lang], :xml)
        fileContent = N42translation::XML.createXML(join_hash_keys(yaml)).target!
        save_with_filename(fileContent, lang, file_prefix, outputfile_path, :xml)
      end
    end

    desc "strings <file_prefix> <outputfile_path>", "converts the content of the yaml file to a android xml file"
    def strings(file_prefix, outputfile_path)
      get_languages(file_prefix).each do |lang|
        yaml = load_yaml([file_prefix, lang], :strings)
        fileContent = N42translation::Strings.createStrings(join_hash_keys(yaml)).join("\n")
        save_with_filename(fileContent, lang, file_prefix, outputfile_path, :strings)
      end
    end

    desc "yml <file_prefix> <outputfile_path>", "converts the content of the yaml file to a rails yaml file, merging in rails specific keys"
    def yml(file_prefix, outputfile_path)
      get_languages(file_prefix).each do |lang|
        yaml = load_yaml([file_prefix, lang], :yml)
        fileContent = yaml.to_yaml
        save_with_filename(fileContent, lang, file_prefix, outputfile_path, :yml)
      end
    end

    private
    def load_yaml(filename_parts, method)
      yaml = YAML.load_file(Array.new(filename_parts).push("yml").join("."))
      
      additional_file = Array.new(filename_parts).push(get_filepart_for_method(method)).push("yml").join(".")

      if File.exist?(additional_file)
        additional_yaml = YAML.load_file(additional_file)

        yaml = yaml.deep_merge(additional_yaml)
      end

      return yaml
    end

    def save_with_filename(content, lang, file_prefix, outputfile_path, method)
      filename = ""

      case method
      when :xml
        filename = "#{outputfile_path}/values-#{lang}/strings.xml"
      when :strings
        filename = "#{outputfile_path}/#{lang}.lproj/Localizable.strings"
      when :yml
        filename = "#{outputfile_path}/#{file_prefix}.#{lang}.yml"
      end
      puts "saving to #{filename}"
      FileUtils.mkdir_p(File.dirname(filename))
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

    # returns the language part of filenames following <file_prefix>.<lang>.yml
    def get_languages(file_prefix)
      yml_files = Dir.glob("#{file_prefix}.*.yml")
      # remove basename
      yml_files.map!{|f| f.slice(file_prefix.length+1, f.length)}
      # get first part until .
      yml_files.map!{|f| f.split(".")[0]}
      # remove duplicates
      yml_files.uniq!

      return yml_files
    end

    def get_filepart_for_method(method)
      case method
      when :xml
        return "android"
      when :strings
        return "ios"
      when :yml
        return "rails"
      else
        rais "unknown method"
      end
    end
  end  
end
