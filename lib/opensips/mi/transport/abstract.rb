# frozen_string_literal: true

require "json"

module Opensips
  module MI
    module Transport
      # abstruct class for transport protocols
      class Abstract
        # connect to network end-point
        def connect
          raise NotImplementedError
        end

        # send a command to connection and return response
        def send(_command)
          raise NotImplementedError
        end

        # request adapter method
        # by default if does jsonrpc v2 as string
        # xmlrpc overload this message
        def adapter_request(cmd, *args)
          rpc = {
            jsonrpc: "2.0",
            id: rand(1 << 16),
            method: cmd
          }

          unless args.empty?
            params = args.flatten
            rpc[:params] = params[0].is_a?(Hash) ? params[0] : params
          end

          JSON.generate(rpc)
        end

        # response adapter by default parses jsonrpc response
        # to an object. xmlrp overloads this method
        def adapter_response(body)
          resp = JSON.parse(body)
          if resp["result"]
            { result: resp["result"] }
          elsif resp["error"]
            { error: resp["error"] }
          else
            { error: { "message" => "invalid response: #{body}" } }
          end
        rescue JSON::ParserError => e
          { error: { "message" => %(JSON::ParserError: #{e}) } }
        end

        protected

        def raise_invalid_params
          raise Opensips::MI::ErrorParams,
                "invalid params. Expecting a hash with :url and optional :timeout"
        end

        def seturi(url)
          @uri = URI(url)
        rescue URI::InvalidURIError
          raise Opensips::MI::ErrorParams,
                "invalid http host url: #{url}"
        end
      end
    end
  end
end
