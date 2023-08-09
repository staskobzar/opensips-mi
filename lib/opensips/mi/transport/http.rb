# frozen_string_literal: true

require "net/http"
require_relative "abstract"

module Opensips
  module MI
    module Transport
      # HTTP transport to communicate with MI
      class HTTP < Abstract
        def initialize(args)
          super()
          raise_invalid_params unless args.is_a?(Hash)
          url, @timeout = args.values_at(:url, :timeout)
          raise_invalid_params if url.nil?
          seturi(url)
          @timeout ||= 5
        end

        def connect
          @client = Net::HTTP.new(@uri.host, @uri.port)
          @client.read_timeout = @timeout
          @client.write_timeout = @timeout
        end

        def send(cmd)
          resp = @client.post(@uri.path, cmd, { "Content-Type" => "application/json" })
          unless resp.code.eql? "200"
            raise Opensips::MI::ErrorHTTPReq,
                  "invalid MI HTTP response: #{resp.message}"
          end
          resp.body
        end
      end
    end
  end
end
