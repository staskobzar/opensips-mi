# frozen_string_literal: true

require "opensips/mi/version"
require "opensips/mi/command"
require "opensips/mi/transport"

module Opensips
  # OpenSIPS Managemen Interface core module
  module MI
    class Error < StandardError; end
    class ErrorParams < Error; end
    class ErrorResolveTimeout < Error; end
    class ErrorSendTimeout < Error; end
    class ErrorHTTPReq < Error; end

    def self.connect(transport_proto, params = {})
      transp = case transport_proto
               when :datagram then Transport::Datagram.new(params)
               when :http then Transport::HTTP.new(params)
               when :xmlrpc then Transport::Xmlrpc.new(params)
               else
                 raise Error, "Unknown transport method: #{transport_proto}"
               end
      Command.new(transp)
    end
  end
end
