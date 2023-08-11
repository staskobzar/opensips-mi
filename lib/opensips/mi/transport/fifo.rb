# frozen_string_literal: true

require_relative "abstract"
require "fcntl"
require "pathname"
require "tempfile"
require "timeout"

module Opensips
  module MI
    module Transport
      # FIFO transport to communicate with MI
      class Fifo < Abstract
        def initialize(args)
          super()
          raise_invalid_params unless args.is_a?(Hash)
          @fifo_name, @reply_dir, @timeout = args.values_at(:fifo_name, :reply_dir, :timeout)
          raise_invalid_params if @fifo_name.nil?
          @reply_dir ||= "/tmp"
          @timeout ||= 5
        end

        def send(rpc)
          reply_file = create_reply_file
          write(reply_file, rpc)
          read(reply_file)
        ensure
          reply_file.unlink if reply_file&.exist?
        end

        protected

        def raise_invalid_params
          raise Opensips::MI::ErrorParams,
                "invalid params. Expecting a hash with :fifo_name and optional :reply_dir"
        end

        private

        def write(reply_file, rpc)
          Timeout.timeout(@timeout, Opensips::MI::ErrorSendTimeout) do
            fifo_wr = IO.open(IO.sysopen(@fifo_name, Fcntl::O_WRONLY))
            fifo_wr.syswrite(%(:#{reply_file.basename}:#{rpc}\n))
            fifo_wr.flush
          ensure
            fifo_wr&.close
          end
        end

        def read(reply_file)
          Timeout.timeout(@timeout, Opensips::MI::ErrorSendTimeout) do
            fifo_rd = IO.open(IO.sysopen(reply_file, Fcntl::O_RDONLY))
            fifo_rd.read
          ensure
            fifo_rd&.close
          end
        end

        def create_reply_file
          tmpfile = Tempfile.create("opensips-mi-reply-", @reply_dir)
          File.unlink(tmpfile)

          File.mkfifo(tmpfile)
          File.chmod(0o666, tmpfile)
          Pathname.new(tmpfile)
        end
      end
    end
  end
end
