require 'yaml'
require 'write_xlsx'

module  N42translation
  class XLSX

    def self.create(csv, output_path, project_name)
      workbook = WriteXLSX.new(output_path)
      worksheet = workbook.add_worksheet(project_name)

      todo_format = workbook.add_format
      todo_format.set_bold
      todo_format.set_color('red')
      todo_format.set_align('left')

      default_format = workbook.add_format
      default_format.set_color('black')
      default_format.set_align('left')

      bold_format = workbook.add_format
      bold_format.set_bold

      csv.each_with_index do |line, row_index|
        contains_unfinished = line.any? {|translation| translation.include? "TODO: "}
        line.each_with_index do |translation, col_index|
          if contains_unfinished
            # write first column red if a translation is missing in column
            if col_index == 0 || (translation.include? "TODO: ")
              worksheet.write(row_index, col_index, translation, todo_format)
            else
              worksheet.write(row_index, col_index, translation, default_format)
            end
          else
            if col_index == 0 || row_index == 0
              # write bold in first col & row
              worksheet.write(row_index, col_index, translation, bold_format)
            else
              worksheet.write(row_index, col_index, translation, default_format)
            end
          end
        end
      end

      workbook.close
    end
  end
end
