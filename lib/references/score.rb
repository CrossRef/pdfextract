require "svm"

module PdfExtract
  module Score

    def self.path_to_data data_filename
      File.join(File.dirname(File.expand_path(__FILE__)), "../../data/" + data_filename)
    end

    @@reference_model = Model.new(path_to_data("reference.model"))

    def self.reference? section
      sample = {
        1 => section[:letter_ratio],
        2 => section[:name_ratio],
        3 => section[:year_ratio],
        4 => section[:cap_ratio],
        5 => section[:lateness]
      }

      puts sample

      puts @@reference_model.predict(sample)
      @@reference_model.predict(sample) > 0
    end

  end
end
