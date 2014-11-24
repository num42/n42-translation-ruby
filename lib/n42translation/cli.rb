require 'thor'
require 'yaml'
require 'active_support'
require 'n42translation/xml'
require 'n42translation/strings'

module N42translation
  class CLI < Thor
    
    desc "build <target> <file_prefix> <outputfile_path>", "builds the files for the target (all, ios, android, rails) for the file_prefix (e.g. horsch) to the outputfile_path (if given, they are taken from the config file otherwise)"
    def build(target, file_prefix, outputfile_path=nil)
      if outputfile_path.nil?
        # there is no output path, use from config file
        config = load_config_file
        if config.nil?
          raise  Thor::Error, "No config file found, add config file or give explicit path"
        else
          puts "using paths from configfile"
          case target.to_sym
          when :all
            build_xml(file_prefix, config["default_path"]["android"])
            build_strings(file_prefix, config["default_path"]["ios"])
            build_yml(file_prefix, config["default_path"]["rails"])
          when :android
            build_xml(file_prefix, config["default_path"]["android"])
          when :ios
            build_strings(file_prefix, config["default_path"]["ios"])
          when :rails
            build_yml(file_prefix, config["default_path"]["rails"])
          else
            raise Thor::Error, "unknown target: #{target}"
          end
        end
      else
         if get_languages(file_prefix).empty?
          raise  Thor::Error, "No files found for file_prefix: #{file_prefix}"
        end

        case target.to_sym
        when :all
          raise Thor::Error, "outputfile_path cannot be used, when target all is defined. Use a config file or call another target"
        when :android
          build_xml(file_prefix, outputfile_path)
        when :ios
          build_strings(file_prefix, outputfile_path)
        when :rails
          build_yml(file_prefix, outputfile_path)
        else
          raise  Thor::Error, "unknown target: #{target}"
        end
      end
    end  

    desc "add <target> <file_prefix> <key> <value>", "Adds the value (e.g. 'my message') to the key (e.g. path.to.my_message) in the target (all, ios, android or rails) for the file_prefix (e.g. horsch)"
    def add(target, file_prefix, key, value)
      get_languages(file_prefix).each do |lang|
        yaml = ""
        if (target.eql? "all")
          yaml = load_yaml([file_prefix, lang])
        else
          yaml = load_yaml([file_prefix, lang, target])
        end
        # hash is a string here
        hash = value
        key.split(".").reverse.each do |keypart|
          # hash is a hash after calling this the first time
          hash = {keypart => hash}
        end
        
        unless yaml
          # Yaml returned false, so it was empty and we set it to hash
          yaml = hash
        else
          yaml = yaml.deep_merge(hash)
        end

        puts yaml.inspect
        fileContent = yaml.to_yaml
        save_with_target(fileContent, lang, file_prefix, target)
      end
    end

    private
    ## Helper

    def load_config_file
      config_path = "n42translation-config.yml"
      if File.exist?(config_path)
        return YAML.load_file(config_path)
      else
        return nil
      end
    end

    # returns the language part of filenames as array following <file_prefix>.<lang>.yml
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

    def save_with_filename(content, lang, file_prefix, outputfile_path, method)
      filename = ""
      case method
      when :xml
        filename = "#{outputfile_path}/values-#{lang}/strings-generated.xml"
      when :strings
        filename = "#{outputfile_path}/#{lang}.lproj/Localizable.strings"
      when :yml
        filename = "#{outputfile_path}/#{file_prefix}.#{lang}.yml"
      end
      puts "saving to #{filename}"
      
      FileUtils.mkdir_p(File.dirname(filename))
      
      File.open(filename, 'w') { |file| file.write(content) }
    end

    def save_with_target(content, lang, file_prefix, target)
      puts ("#{target}")
      if target.eql? "all"
        filename = "#{file_prefix}.#{lang}.yml"
      else
        filename = "#{file_prefix}.#{lang}.#{target}.yml"
      end

      puts "saving to #{filename}"
      
      FileUtils.mkdir_p(File.dirname(filename))
      
      File.open(filename, 'w') { |file| file.write(content) }
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
        raise "unknown method"
      end
    end

    def load_yaml(filename_parts)
      filename = Array.new(filename_parts).push("yml").join(".")
      if File.exist?(filename)
        return YAML.load_file(filename)
      else
        return {}
      end
    end

    def load_merged_yaml_for_method(filename_parts, method)
      yaml = load_yaml(filename_parts)
      additional_file = Array.new(filename_parts).push(get_filepart_for_method(method)).push("yml").join(".")
      if File.exist?(additional_file)
        additional_yaml = YAML.load_file(additional_file)
        yaml = yaml.deep_merge(additional_yaml)
      end
      return yaml
    end

    ## Builder

    def build_xml(file_prefix, outputfile_path)
      get_languages(file_prefix).each do |lang|
        yaml = load_merged_yaml_for_method([file_prefix, lang], :xml)
        fileContent = N42translation::XML.createXML(join_hash_keys(yaml, "_")).target!
        save_with_filename(fileContent, lang, file_prefix, outputfile_path, :xml)
      end
    end

    def build_strings(file_prefix, outputfile_path)
      get_languages(file_prefix).each do |lang|
        yaml = load_merged_yaml_for_method([file_prefix, lang], :strings)
        fileContent = N42translation::Strings.createStrings(join_hash_keys(yaml, ".")).join("\n")
        save_with_filename(fileContent, lang, file_prefix, outputfile_path, :strings)
      end
    end

    def build_yml(file_prefix, outputfile_path)
      get_languages(file_prefix).each do |lang|
        yaml = load_merged_yaml_for_method([file_prefix, lang], :yml)
        fileContent = yaml.to_yaml
        save_with_filename(fileContent, lang, file_prefix, outputfile_path, :yml)
      end
    end

    
    ## Hash Helper
 
    # flatten the hash, ["a" => ["b" => "c"]] becomes [["a", "b"]=>"c"]
    def flat_hash(h,f=[],g={})
      return g.update({ f=>h }) unless h.is_a? Hash
        h.each { |k,r| flat_hash(r,f+[k],g) }
        g
    end

    # flatten and jon the hash keys, [["a", "b"]=>"c"] becomes ["a.b"=>"c"]
    def join_hash_keys(hash, joiner)
      Hash[flat_hash(hash).map {|k, v| [k.join(joiner), v] }]
    end

  end  
end
