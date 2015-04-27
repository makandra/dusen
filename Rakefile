require 'rake'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => 'all:spec'

namespace :travis_ci do

  desc 'Things to do before Travis CI begins'
  task :prepare => :slimgems do
    Rake::Task['travis_ci:create_database'].invoke &&
    Rake::Task['travis_ci:create_database_yml'].invoke
  end

  desc 'Install slimgems'
  task :slimgems do
    system('gem install slimgems')
  end

  desc 'Creates a test database'
  task :create_database do
    system("mysql -e 'create database dusen_test;'")
  end

  desc 'Creates a database.yml'
  task :create_database_yml do
    config_dir = "spec/shared/app_root/config"
    system("cp #{config_dir}/database.sample.yml #{config_dir}/database.yml")
  end

end

namespace :all do

  desc "Run specs on all spec apps"
  task :spec do
    success = true
    for_each_directory_of('spec/**/Rakefile') do |directory|
      env = "SPEC=../../#{ENV['SPEC']} " if ENV['SPEC']
      success &= system("cd #{directory} && #{env} bundle exec rake spec")
    end
    fail "Tests failed" unless success
  end

  desc "Bundle all spec apps"
  task :bundle do
    for_each_directory_of('spec/**/Gemfile') do |directory|
      system("cd #{directory} && bundle install")
    end
  end

  desc 'Install gems and run tests on several Ruby versions'
  task :rubies do
    success = case
    when system('which rvm')
      run_for_all_rubies :rvm
    when system('which rbenv') && `rbenv commands`.split("\n").include?('alias')
      # rbenv currently works only with the alias plugin, as we do not want to
      # specify Ruby versions down to their patch levels.
      run_for_all_rubies :rbenv
    else
      fail 'Currently only RVM and rbenv (with alias plugin) are supported. Open Rakefile and add your Ruby version manager!'
    end

    fail "Tests failed" unless success
  end

end

def for_each_directory_of(path, &block)
  Dir[path].sort.each do |rakefile|
    directory = File.dirname(rakefile)
    puts '', "\033[44m#{directory}\033[0m", ''
    block.call(directory)
  end
end

def run_for_all_rubies(version_manager)
  %w[
    1.8.7
    1.9.3
    2.1.2
  ].all? do |ruby_version|
    announce "Running bundle and specs for Ruby #{ruby_version}", 2

    execute = case version_manager
    when :rvm
      "rvm #{ruby_version} do"
    when :rbenv
      ENV['RBENV_VERSION'] = ruby_version
      'rbenv exec'
    end

    current_version = `#{execute} ruby -v`.match(/^ruby (\d\.\d\.\d)/)[1]
    if current_version == ruby_version
      puts "Currently active Ruby is #{current_version}"
      system "#{execute} rake all:bundle all:spec"
    else
      fail "Failed to set Ruby #{ruby_version} (#{current_version} active!)"
    end
  end
end

def announce(text, level = 1)
  space = "\n" * level
  message = "# #{text}"
  puts "\e[4;34m#{space + message}\e[0m" # blue underline
end
