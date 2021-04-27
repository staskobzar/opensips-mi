require 'ostruct'
require 'fcntl'
require 'securerandom'
require 'socketry'
require 'xmlrpc/client'

require "opensips/mi/version"
require "opensips/mi/response"
require "opensips/mi/command"
require "opensips/mi/transport"

module Opensips
  module MI
    def self.connect(transport, params)
      # send to transport class
      Transport.const_get(transport.to_s.capitalize).init params
    rescue NameError
      raise NameError, "Unknown transport method: " << transport.to_s
    end
  end
end

