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
          @sock = Socketry::UDP::Socket.connect(params[:host], params[:port])
          @timeout = params[:timeout].to_i
        end

        def command(cmd, params = [])
          request = ":#{cmd}:\n"
          params.each do |c|
            request << "#{c}\n"
          end
          response = send(request)
          Opensips::MI::Response.new response.split(?\n)
        end

        def tout
          @timeout > 0 ? @timeout : TIMEOUT
        end

        private
        def send(request)
          @sock.send request
          response = @sock.recvfrom RECVMAXLEN, timeout: tout
          response.message
        rescue => e
          "500 #{e}"
        end
      end
    end
  end
end
