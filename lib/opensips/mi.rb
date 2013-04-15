require 'ostruct'
require 'fcntl'
require 'securerandom'
require 'socket'
require 'xmlrpc/client'

require "opensips/mi/version"
require "opensips/mi/response"
require "opensips/mi/command"
require "opensips/mi/transport"

module Opensips
  module MI
    def self.connect(transport, params)
      class_name = transport.to_s.capitalize
      # send to transport class
      Transport.const_get(class_name).init params
    rescue NameError => e
      raise NameError, "Unknown transport method: " << transport.to_s
    end
  end
end

