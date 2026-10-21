require 'rbconfig'

ENV['PATH'] = [RbConfig::CONFIG.fetch('bindir'), ENV.fetch('PATH')].join(File::PATH_SEPARATOR)
exec(*ARGV)
