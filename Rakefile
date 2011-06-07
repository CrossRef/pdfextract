require 'rubygems'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = 'PDF text, region, section and section header extraction tool and library.'
  s.name = 'pdf-extract'
  s.version = '0.0.1'
  s.require_path = 'lib'
  s.files = ['lib/**/*.rb', 'bin/*', '[A-Z]*', 'test/**/*'].to_a
  s.author = 'Karl Jonathan Ward'
  s.required_ruby_version = '>= 1.9.1'

  s.add_dependency 'pdf-reader', '>= 0.9.2'
  s.add_dependency 'nokogiri', '>= 1.4.4'

  s.executables << 'pdf-extract'
end

Rake::GemPackageTask.new spec do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end
