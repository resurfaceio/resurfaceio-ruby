# coding: utf-8
# Copyright (c) 2016 Resurface Labs LLC, All Rights Reserved

require 'uri'
require 'net/http'
require 'net/https'
require 'resurfaceio/json_message'

class HttpLogger

  SOURCE = 'resurfaceio-logger-ruby'

  URL = 'https://resurfaceio.herokuapp.com/messages'

  def initialize(url = URL, enabled = true)
    @enabled = enabled
    @tracing = false
    @tracing_history = []
    @url = url
    @version = HttpLogger.version_lookup
  end

  def disable
    @enabled = false
    self
  end

  def enable
    @enabled = true
    self
  end

  def enabled?
    @enabled
  end

  def format_echo(json, now)
    JsonMessage.start(json, 'echo', SOURCE, version, now)
    JsonMessage.finish(json)
  end

  def format_request(json, now, request)
    JsonMessage.start(json, 'http_request', SOURCE, version, now) << ','
    JsonMessage.append(json, 'url', request.url)
    JsonMessage.finish(json)
  end

  def format_response(json, now, response, body=nil)
    JsonMessage.start(json, 'http_response', SOURCE, version, now) << ','
    JsonMessage.append(json, 'code', response.status)
    unless body.nil? && response.body.nil?
      json << ','
      JsonMessage.append(json, 'body', body.nil? ? response.body : body)
    end
    JsonMessage.finish(json)
  end

  def log_echo
    if @enabled || @tracing
      json = format_echo(String.new, Time.now.to_i)
      post(json).eql?(200)
    else
      true
    end
  end

  def log_request(request)
    if @enabled || @tracing
      json = format_request(String.new, Time.now.to_i, request)
      post(json).eql?(200)
    else
      true
    end
  end

  def log_response(response, body=nil)
    if @enabled || @tracing
      json = format_response(String.new, Time.now.to_i, response, body)
      post(json).eql?(200)
    else
      true
    end
  end

  def post(json)
    if @tracing
      @tracing_history << json
      200
    else
      begin
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(uri.path)
        request.body = json
        response = https.request(request)
        response.code.to_i
      rescue SocketError
        404
      end
    end
  end

  def tracing?
    @tracing
  end

  def tracing_history
    @tracing_history
  end

  def tracing_start
    @tracing = true
    @tracing_history = []
    self
  end

  def tracing_stop
    @tracing = false
    @tracing_history = []
    self
  end

  def url
    @url
  end

  def version
    @version
  end

  def self.version_lookup
    Gem.loaded_specs['resurfaceio-logger'].version.to_s
  end

end
