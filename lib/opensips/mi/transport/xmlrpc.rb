# frozen_string_literal: true

require_relative "abstract"
require "xmlrpc/client"

module Opensips
  module MI
    module Transport
      # XML-RPC protocol for MI
      class Xmlrpc < Abstract
        def initialize(args)
          super()
          raise_invalid_params unless args.is_a?(Hash)
          url, @timeout = args.values_at(:url, :timeout)
          raise_invalid_params if url.nil?
          seturi(url)
        end

        def connect
          @client = XMLRPC::Client.new2(@uri.to_s, nil, @timeout)
        end

        def send(*cmd)
          @client.call(*cmd)
        rescue XMLRPC::FaultException => e
          { error: { "message" => e.message } }
        rescue StandardError => e
          raise Opensips::MI::ErrorHTTPReq, e
        end

        # overload resonse adapter for xmlrpc
        def adapter_response(resp)
          if resp[:error]
            resp
          else
            { result: resp }
          end
        end

        # overload request adapter for xmlrpc
        def adapter_request(*args)
          args.flatten => [cmd, *rest]
          return [cmd] if rest.empty?

          rest = rest.flatten
          return [cmd, rest.first.map { |_, v| v }].flatten if rest.first.is_a?(Hash)

          [cmd, rest].flatten
        end
      end
    end
  end
end
