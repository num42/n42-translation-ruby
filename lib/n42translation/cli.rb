require 'thor'
require 'yaml'
require 'active_support'
require 'n42translation/xml'
require 'n42translation/strings'
require 'n42translation/csv_convert'
require 'fileutils'
require 'csv'

module N42translation
  class CLI < Thor

    desc "init <project-name> <target> <languages>", "init"
    def init(project_name, target = nil, languages = nil)
      config = load_config_file(project_name)

      build_path = config["build_path"]
      source_path = config["source_path"]

      project_name = config["project_name"] if project_name.nil?

      targets = []
      targets = [target] if target != nil && target != ""
      targets = config["targets"]["all"].split(',').map(&:lstrip).map(&:rstrip) if target === "all"
      targets = config["targets"]["mobile"].split(',').map(&:lstrip).map(&:rstrip) if target === "mobile"
      targets << "" # we want a platform named "all", to build from 'platform' + 'all' files

      raise Thor::Error, "no build path found" if build_path.nil?
      raise Thor::Error, "no locale path found" if source_path.nil?
      raise Thor::Error, "no project name was specified" if project_name.nil?
      raise Thor::Error, "no targets specified" if targets.nil?

      languages = config["languages"] if languages.nil?
      langs = languages.split(',').map(&:lstrip).map(&:rstrip)
      langs = (langs + get_languages(project_name)).uniq

      targets.each do |_target|
        build(_target, project_name, build_path) unless _target == "all"

        langs.each do |lang|
          filename = File.join(source_path, "#{project_name}.#{lang}.yml") if _target ===""
          filename = File.join(source_path, "#{project_name}.#{lang}.#{_target}.yml") unless _target === ""
          File.open(filename, 'w') { |file| file.write("---") } unless File.exists?(filename)
        end
      end
    end

    desc "build <target> <project_name> <outputfile_path> <default-language>", "builds the files for the target (all, ios, android, rails) for the project_name (e.g. horsch) to the outputfile_path (if given, they are taken from the config file otherwise)"
    def build(target, project_name, outputfile_path=nil, default_language="en")
      config = load_config_file(project_name)

      outputfile_path = config["build_path"] if outputfile_path.nil?
      raise Thor::Error, "no output path specified" if outputfile_path.nil?

      source_path = config["source_path"]
      raise Thor::Error, "no source path specified" if source_path.nil?

      path_name = config["target_build_path_names"][target.to_s].to_s
      target_build_path = File.join(outputfile_path, path_name)

      case target.to_sym
      when :all
        self.build(:android, project_name, outputfile_path)
        self.build(:ios, project_name, outputfile_path)
        self.build(:rails, project_name, outputfile_path)
        self.build(:csv, project_name, outputfile_path)
      when :android
        raise Thor::Error, "no build path specified for your target: #{target}" if target_build_path.nil?
        build_platform(source_path, project_name, target_build_path, target, :xml)
      when :ios
        raise Thor::Error, "no build path specified for your target: #{target}" if target_build_path.nil?
        build_platform(source_path, project_name, target_build_path, target, :strings)
      when :rails
        raise Thor::Error, "no build path specified for your target: #{target}" if target_build_path.nil?
        build_platform(source_path, project_name, target_build_path, target, :yml)
      when :csv
        raise Thor::Error, "no build path specified for your target: #{target}" if target_build_path.nil?
        build_csv(source_path, project_name, target_build_path, [:all, :ios, :android, :rails], default_language)
        # build_platform(source_path, project_name, target_build_path, target, :csv)
      when "".to_sym
        # ignore the “” case
      else
        raise Thor::Error, "unknown target: #{target}"
      end
    end

    desc "add <target> <project_name> <key> <value> <language>", "creates or updates the specified <value> for the <key> in the <target> in the project <project_name> for the specified <language>(default: 'en') will add a 'TODO: <value>(<language>)' to all other languages"
    def add(target, project_name, key, value, language = "en")
      insert_string(target, project_name, key, value, language, :override)
    end
    #
    # desc "update <target> <project_name> <key> <value> <language>", "updates or creates the specified <value> for the <key> in the <target> for the project <project_name>. Optional is language(default: 'en') will add to specific <language>"
    # def update(target, project_name, key, new_value, language="en")
    #   insert_string(target, project_name, key, new_value, language, :update)
    # end
    #
    #

    private
    ## Helper

    # inserts string into languages
    def insert_string(target, project_name, key, value, language = "en", mode)
      config = load_config_file(project_name)
      source_path = config["source_path"]

      get_languages(project_name).each do |lang|
        if lang === language
          val = value
          insert_string_into_language(key, value, lang, source_path, project_name, target)
        else
          next if mode === :update
          val = "TODO: #{value}(#{language.upcase})"
          insert_string_into_language(key, val, lang, source_path, project_name, target) if mode === :override
        end
      end
    end

    def insert_string_into_language(key, value, language, source_path, project_name, target)
      # hash is a string here
      hash = value

      key.split(".").reverse.each do |keypart|
        # hash is a hash after calling this the first time
        hash = {keypart => hash}
      end

      fileContent = yaml_for_platform_and_lang(source_path, project_name, target.to_sym, language).deep_merge(hash).to_yaml
      save_with_target(fileContent, language, project_name, target)
    end

    def load_config_file(project_name = "default")
      default_path = "./config.default.yml"
      project_path = "./config.#{project_name}.yml"
      default_yaml = load_yaml(default_path)
      project_yaml = load_yaml(project_path)

      return default_yaml if project_yaml.nil? || project_yaml == false
      default_yaml.deep_merge(project_yaml)
    end

    # returns the language part of filenames as array following <project_name>.<lang>.yml
    def get_languages(project_name)
      config = load_config_file(project_name)

      source_path = config["source_path"]
      raise Thor::Error, "no locale path found" if source_path.nil?

      langs = Dir.glob("#{source_path}/#{project_name}.*.yml").map{|f| File.basename(f,".yml").split(".")[1]}
      langs.uniq
    end

    def save_with_filename(content, lang, project_name, outputfile_path, method)
      filename = ""
      case method
      when :xml
        filename = "#{outputfile_path}/values-#{lang}/strings-generated.xml"
      when :strings
        filename = "#{outputfile_path}/#{lang}.lproj/Localizable.strings"
      when :yml
        filename = "#{outputfile_path}/#{project_name}.#{lang}.yml"
      end

      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |file| file.write(content) }
    end

    def save_with_target(content, lang, project_name, target)
      filename = "#{project_name}.#{lang}.yml"  if target.eql? "all"
      filename = "#{project_name}.#{lang}.#{target}.yml" unless target.eql? "all"

      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |file| file.write(content) }
    end

    def load_yaml(file_path)
      if File.exist?(file_path)
        YAML.load_file(file_path) || {}
      else
        return {}
      end
    end

    def load_merged_yaml_for_platform(source_path, project_name, language, platform)
      yaml = load_yaml(File.join(source_path,"#{project_name}.#{language}.yml"))
      target_yaml = load_yaml(File.join(source_path,"#{project_name}.#{language}.#{platform.to_s}.yml"))
      return yaml.deep_merge(target_yaml) if !target_yaml.nil? || target_yaml === false
      yaml
    end

    ## Builder
    def build_platform(source_path, project_name, outputfile_path, platform, method)
      get_languages(project_name).each do |lang|
        yaml = load_merged_yaml_for_platform(source_path, project_name, lang, platform)
        fileContent = ""
        fileContent = N42translation::XML.createXML(join_hash_keys(yaml, "_")).target! if method == :xml
        fileContent = N42translation::Strings.createStrings(join_hash_keys(yaml, ".")).join("\n") if method == :strings
        fileContent = yaml.to_yaml if method == :yml
        save_with_filename(fileContent, lang, project_name, outputfile_path, method)
      end
    end

    def build_csv(source_path, project_name, outputfile_path, platforms, default_language)
      languages = get_languages(project_name)
      language_yamls = {}
      languages.each do |language|
        language_yamls["#{language}"] = platforms.map {|platform| yaml_for_platform_and_lang(source_path, project_name, platform, language) }.reduce({}, :merge)
      end

      csv_data = N42translation::CSVConvert.createCSV(language_yamls.values.map{|yml| join_hash_keys(yml,'.')}, languages, join_hash_keys(language_yamls[default_language],'.'), default_language)

      filename = File.join(outputfile_path,'csv',"#{project_name}.csv")
      FileUtils.mkpath(File.dirname(filename))
      File.open(filename, "w") {|f| f.write(csv_data.inject([]) { |csv, row|  csv << CSV.generate_line(row) }.join(""))}
    end

    def yaml_for_platform_and_lang(source_path, project_name, platform, language)
      if platform == :all
        load_yaml(File.join(source_path,"#{project_name}.#{language}.yml")).to_h
      else
        load_yaml(File.join(source_path,"#{project_name}.#{language}.#{platform.to_s}.yml")).to_h
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
