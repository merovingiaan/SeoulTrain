# encoding: utf-8
RACK_ENV = ENV['RACK_ENV'] ||= 'test' unless defined?(RACK_ENV)
RACK_ENV_SYM = RACK_ENV.to_sym

require 'bundler/setup'
require 'sinatra'
require 'rspec'
require 'capybara'
require 'capybara/dsl'
require File.dirname(__FILE__) + '/../app'
disable :run

Sinatra::Application.environment = RACK_ENV_SYM
Bundler.require :default, Sinatra::Application.environment
Capybara.app = Sinatra::Application

RSpec.configure do |config|
  config.include Capybara::DSL
end