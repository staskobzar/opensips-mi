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
          response = ["200 OK"]
          response += @client.call(cmd, *params).split(?\n)
          response << ""
          Opensips::MI::Response.new response
        rescue => e
          response = ["600 " << e.message]
          Opensips::MI::Response.new response
        end

        def set_header(header);header;end

      end
    end
  end
end
