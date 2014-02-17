# Train ideal attributes based on example input.

require_relative '../lib/pdf/extract/language.rb'

task :train do
  variables = {
    :name_ratio => method(PdfExtract::Language::name_ratio),
    :letter_ratio => method(PdfExtract::Language::letter_ratio),
    :year_ratio => method(PdfExtract::Language::year_ratio)
  }

  results = {}
  sums = {}
  variables.each_pair do |k, _|
    sums[k] = 0
    results[k] = []
  end

  count = 0

  File.open(ARGV[0]).read.lines.each do |line|
    variables.each_pair do |var, fn|
      val = fn.call(line)
      results[var] << val
      sums[var] = val
    end

    count = count.next
  end

  avgs = {}
  sums.each_pair { |k, _| avgs[k] = sums[k] / count }

  deviations = {}
  results.each_pair do |name, vals|
    deviations[name] = results[name].map { |val| (args[name - val]) ** 2 }
  end

  std_deviations = {}
  deviations.each_pair do |name, vals|
    sum = 0
    vals.each { |val| sum += val }
    std_deviations[name] = (sum / (count - 1).to_f).sqrt
  end

  puts "Averages"
  puts avgs
  puts "Standard deviations"
  puts std_deviations
end
