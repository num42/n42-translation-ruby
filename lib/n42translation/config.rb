require 'yaml'

module N42translation
  class Config
    def self.default_yml
      YAML.load('
        build_path: ./builds
        source_path: ./
        project_name: n42translation_project
        languages: de,en
        targets:
          all: ios,android,rails,csv,xlsx
          mobile: ios,android
        target_build_path_names:
          android: Android
          ios: iOS
          rails: Rails
          csv: CSV
          xlsx: EXCEL
      ')
    end
  end
end
