module Opensips
  module MI
    module Transport
      class Xmlrpc < Opensips::MI::Command
        RPCSEG = 'RPC2'
        class << self
          def init(params)
            Xmlrpc.new params
          end
        end

        def initialize(params)
          raise ArgumentError,
            'Missing socket host' if params[:host].nil?
          raise ArgumentError,
            'Missing socket port' if params[:port].nil?
          Socket.getaddrinfo(params[:host], nil) rescue 
            raise SocketError, "Invalid host #{params[:host]}" 
          raise SocketError, 
            "Invalid port #{params[:port]}" unless (1..(2**16-1)).include?(params[:port])
          uri = "http://#{params[:host]}:#{params[:port]}/#{RPCSEG}"
          @client = XMLRPC::Client.new_from_uri(uri, nil, 3)
        rescue => e
          raise e.class,
            "Can not connect OpenSIPs server.\n#{e.message}"
        end

        def command(cmd, params = [])
          response = @client.call cmd, *params
          Opensips::MI::Response.new response.split(?\n)
        end

      end
    end
  end
end
