# coding: utf-8
# Copyright (c) 2016 Resurface Labs LLC, All Rights Reserved

require 'resurfaceio/logger'
require_relative 'helper'

describe HttpLoggerForRails do

  it 'uses module namespace' do
    expect(HttpLoggerForRails.class.equal?(Resurfaceio::HttpLoggerForRails.class)).to be true
  end

  it 'logs html response' do
    logger = HttpLoggerFactory.get.disable.tracing_start
    begin
      HttpLoggerForRails.new.around(MockRailsHtmlController.new) {}
      expect(logger.tracing_history.length).to eql(2)
      json = logger.tracing_history[0]
      expect(parseable?(json)).to be true
      expect(json.include?("\"body\"")).to be false
      expect(json.include?("\"category\":\"http_request\"")).to be true
      expect(json.include?("\"headers\":[]")).to be true
      expect(json.include?("\"method\":\"GET\"")).to be true
      expect(json.include?("\"url\":\"#{MOCK_URL}\"")).to be true
      json = logger.tracing_history[1]
      expect(parseable?(json)).to be true
      expect(json.include?("\"body\":\"#{MOCK_HTML_ESCAPED}\"")).to be true
      expect(json.include?("\"category\":\"http_response\"")).to be true
      expect(json.include?("\"code\":200")).to be true
      expect(json.include?("\"headers\":[]")).to be true
    ensure
      logger.tracing_stop.enable
    end
  end

  it 'logs html response to json request' do
    logger = HttpLoggerFactory.get.disable.tracing_start
    begin
      HttpLoggerForRails.new.around(MockRailsJsonController.new) {}
      expect(logger.tracing_history.length).to eql(2)
      json = logger.tracing_history[0]
      expect(parseable?(json)).to be true
      expect(json.include?("\"body\":\"#{MOCK_JSON_ESCAPED}\"")).to be true
      expect(json.include?("\"category\":\"http_request\"")).to be true
      expect(json.include?("\"headers\":[{\"content-type\":\"application/json\"}]")).to be true
      expect(json.include?("\"method\":\"POST\"")).to be true
      expect(json.include?("\"url\":\"#{MOCK_URL}\"")).to be true
      json = logger.tracing_history[1]
      expect(parseable?(json)).to be true
      expect(json.include?("\"body\":\"#{MOCK_HTML_ESCAPED}\"")).to be true
      expect(json.include?("\"category\":\"http_response\"")).to be true
      expect(json.include?("\"code\":200")).to be true
      expect(json.include?("\"headers\":[]")).to be true
    ensure
      logger.tracing_stop.enable
    end
  end

end
