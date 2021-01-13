require 'timeout'

module Opensips
  module MI
    module Transport
      class Datagram < Opensips::MI::Command
        RECVMAXLEN = 2**16 - 1
        TIMEOUT = 3

        class << self
          def init(params)
            Datagram.new params
          end
        end

        def initialize(params)
          host_valid? params
          @sock = UDPSocket.new
          @sock.connect params[:host], params[:port]
          @timeout = params[:timeout].to_i
        end

        def command(cmd, params = [])
          request = ":#{cmd}:\n"
          params.each do |c|
            request << "#{c}\n"
          end
          Timeout::timeout(tout, nil, "Timeout send request to datagram MI") {
            @sock.send request, 0
          }
          # will raise Errno::ECONNREFUSED if failed to connect
          Timeout::timeout(tout,nil,"Timeout receive respond from datagram MI") {
            response, = @sock.recvfrom RECVMAXLEN
          }
          Opensips::MI::Response.new response.split(?\n)
        end

        def tout
          @timeout > 0 ? @timeout : TIMEOUT
        end

      end
    end
  end
end
