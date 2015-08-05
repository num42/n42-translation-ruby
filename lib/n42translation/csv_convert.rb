require 'yaml'

module N42translation
  class CSVConvert
    def self.createCSV(ymls, langs, default_yml, default_language)

      keys = ymls.map{|yml| yml.keys }.flatten.uniq

      rows = []
      rows << ["key",langs].flatten

      keys.each do |key|
        rows << [key, get_values_from_key(ymls, key, default_yml, default_language)].flatten
      end

      rows
    end

    private
    def self.get_values_from_key(ymls, key, default_yml, default_language)
      ymls.map do |yml|
        val = yml[key.to_s]
        if yml[key.to_s].nil?
          default_val = default_yml[key.to_s]
          if default_val.nil?
            "TODO: "
          else
            "TODO: #{default_val}(#{default_language.to_s.upcase})"
          end
        else
          val
        end
      end
    end
  end
end
