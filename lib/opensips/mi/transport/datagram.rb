# frozen_string_literal: true

require_relative "abstract"
require "socket"
require "timeout"

module Opensips
  module MI
    module Transport
      # datagram UDP transport to communicate with MI
      class Datagram < Abstract
        def initialize(args)
          super()
          raise_invalid_params unless args.is_a?(Hash)
          @host, @port, @timeout = args.values_at(:host, :port, :timeout)
          raise_invalid_params if @host.nil? || @port.nil?
          raise_invalid_port unless @port.to_i.between?(1, 1 << 16)
          @timeout ||= 5
          connect
        end

        def send(command)
          Timeout.timeout(
            @timeout,
            Opensips::MI::ErrorSendTimeout,
            "timeout send command to #{@host}:#{@port} within #{@timeout} sec"
          ) do
            @sock.send command, 0
            msg, = @sock.recvfrom(1500)
            msg
          end
        end

        protected

        def raise_invalid_params
          raise Opensips::MI::ErrorParams,
                "invalid params. Expecting a hash with :host, :port and optional :timeout"
        end

        def raise_invalid_port
          raise Opensips::MI::ErrorParams, "invalid port '#{@port}'"
        end

        private

        def connect
          @sock = UDPSocket.new
          Timeout.timeout(
            @timeout,
            Opensips::MI::ErrorResolveTimeout,
            "failed to resolve address #{@host}:#{@port} within #{@timeout} sec"
          ) { @sock.connect(@host, @port) }
        end
      end
    end
  end
end
