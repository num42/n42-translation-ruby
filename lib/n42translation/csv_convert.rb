require 'yaml'

module N42translation
  class CSVConvert
    def self.createCSV(language_hashes, langs, default_yml, default_language)

      keys = language_hashes.dup.map do |lang, lang_hash|
        lang_hash.keys
      end.flatten.uniq

      rows = []
      rows << ["key",langs].flatten

      keys.each do |key|
        rows << [
          key,
          get_values_from_key(language_hashes, key, default_yml, default_language)
        ].flatten
      end

      rows
    end

    private

    def self.get_values_from_key(language_hashes, key, default_yml, default_language)
      default_language_name = default_language.to_s.upcase
      language_hashes.map do |lang, language_hash|
        val = language_hash[key.to_s]
        if val.nil?
          default_val = default_yml[key.to_s]
          "TODO: #{default_val.nil? ? '' : "#{default_val}(#{default_language_name})"}"
        else
          val
        end
      end
    end
  end
end
