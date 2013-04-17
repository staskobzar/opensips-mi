module Opensips
  module MI
    module Transport
      class Datagram < Opensips::MI::Command
        RECVMAXLEN = 2**16 - 1

        class << self
          def init(params)
            Datagram.new params
          end
        end

        def initialize(params)
          host_valid? params
          @sock = UDPSocket.new
          @sock.connect params[:host], params[:port]
        end

        def command(cmd, params = [])
          request = ":#{cmd}:\n"
          params.each do |c|
            request << "#{c}\n"
          end
          @sock.send request, 0
          # will raise Errno::ECONNREFUSED if failed to connect
          response, = @sock.recvfrom RECVMAXLEN
          Opensips::MI::Response.new response.split(?\n)
        end

      end
    end
  end
end
