# This spec needs rubygem-rack, rubygem-capybara and rubygem-rspec installed.
# Run as `rspec spec/` in the project root directory.

require 'rack'
require 'capybara'
require 'capybara/dsl'
require 'capybara/session'
require 'capybara/rspec'
require_relative './shared_contexts.rb'

class JekyllSite
  attr_reader :root, :file_server, :res_server

  def initialize(root)
    @root = root
    @file_server = Rack::File.new(root)

    site_path = File.join(File.dirname(__FILE__), '..', '_site')
    @res_server = Rack::File.new(File.expand_path(site_path))
  end

  def call(env)
    path = env['PATH_INFO']

    # Use index.html for / paths
    if path == '/' && exists?('index.html')
      env['PATH_INFO'] = '/index.html'
    elsif !exists?(path) && exists?(path + '.html')
      env['PATH_INFO'] += '.html'
    elsif exists?(path) && directory?(path) && exists?(File.join(path, 'index.html'))
      env['PATH_INFO'] += '/index.html'
    end

    file_server.call(env)
  end

  def exists?(path)
    File.exist?(File.join(root, path))
  end

  def directory?(path)
    File.directory?(File.join(root, path))
  end
end

# Setup for Capybara to test Jekyll static files served by Rack
Capybara.app = Rack::Builder.new do
  map '/' do
    use Rack::Lint
    run JekyllSite.new(File.join(File.dirname(__FILE__), '..', '_site'))
  end
end.to_app

Capybara.default_selector =  :css
Capybara.default_driver   =  :rack_test
Capybara.javascript_driver = :webkit

RSpec.configure do |config|
  config.include Capybara::DSL

  # Make sure the static files are generated
  `jekyll build` unless File.directory?('_site')
end
