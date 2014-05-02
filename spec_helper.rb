# encoding: utf-8
RACK_ENV = ENV['RACK_ENV'] ||= 'test' unless defined?(RACK_ENV)
RACK_ENV_SYM = RACK_ENV.to_sym

require './app'
require 'bundler/setup'
require 'rspec'
