module Opensips
  module MI
    module Transport
      class Fifo < Opensips::MI::Command
        PERMISIONS = '0666'
        attr_accessor :reply_fifo       # name of the reply fifo file 
        attr_accessor :fifo_name        # OpenSIPs fifo file. See mi_fifo module
        attr_accessor :reply_dir        # path to directory with where the reply fif is located

        class << self
          def init(params)
            fifo = Fifo.new params
            fifo.open
          end
        end

        def initialize(params)
          # set default values
          @reply_fifo = if params[:reply_fifo].nil?
                          "opensips_reply_" << SecureRandom.hex[0,8]
                        else
                          @reply_fifo = params[:reply_fifo]
                        end

          @reply_dir  = if params[:reply_dir].nil?
                          '/tmp/'
                        else
                          params[:reply_dir]
                        end
          raise ArgumentError,
            "Fifo reply directory does not exists #{@reply_dir}" unless Dir.exists? @reply_dir 

          # fifo_name is required parameter
          raise ArgumentError, 
            'Missing required parameter fifo_name' if params[:fifo_name].nil?

          @fifo_name      = params[:fifo_name]
          raise ArgumentError,
            "OpenSIPs fifo_name file does not exist: #{@fifo_name}" unless File.exists? @fifo_name
          raise ArgumentError,
            "File #{@fifo_name} is not pipe" unless File.pipe? @fifo_name
          
          # set finalizing method
          reply_file = File.expand_path(@reply_fifo, @reply_dir) 
          ObjectSpace.define_finalizer(self, proc{self.class.finalize(reply_file)})
        end

        def open
          # create fifo file
          fifo_file = File.expand_path(@reply_fifo, @reply_dir)
          Kernel.system "mkfifo -m #{PERMISIONS} #{fifo_file}" 
          raise SystemCallError,
            "Can not create reply pipe: #{fifo_file}" unless File.pipe?(fifo_file) 
          self
        end

        def command(cmd, params = [])
          fd_w   = IO::sysopen(@fifo_name, Fcntl::O_WRONLY)
          fifo_w  = IO.open(fd_w)

          request = ":#{cmd}:#{@reply_fifo}\n"
          params.each do |c|
            request << "#{c}\n"
          end
          # additional new line to terminate command
          request << ?\n
          fifo_w.syswrite request

          # read response
          file   = File.expand_path(File.expand_path(@reply_fifo,@reply_dir))
          fd_r   = IO::sysopen(file, Fcntl::O_RDONLY )
          fifo_r = IO.open(fd_r)

          response = Array[]
          response << $_.chomp while fifo_r.gets
          Opensips::MI::Response.new response
        ensure
          # make sure we always close files' descriptors
          fifo_r.close if fifo_r
          fifo_w.close if fifo_w
        end

        def self.finalize(reply_file)
          File.unlink(reply_file) if File.exists?(reply_file)
        end

      end
    end
  end
end
