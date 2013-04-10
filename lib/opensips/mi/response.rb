module Opensips
  module MI
    class Response
      attr_reader :code, :success, :message
      attr_reader :data

      def initialize(data)
        raise InvalidResponseData, 
          'Invalid parameter' unless data.is_a? Array
        raise EmptyResponseData, 
          'Empty parameter array' if data.empty?
        
        if /^(?<code>\d+) (?<message>.+)$/ =~ data.shift.to_s
          @code = code.to_i
          @message = message
        else
          raise InvalidResponseData,
            'Invalid response parameter. Can not parse'
        end

        @success = (200..299).include?(@code)

        # successfull responses have additional new line
        data.pop if @success
        @data = data
      end
      
      # Parse user locations records to Hash
      def ul_dump
        return nil unless /^Domain:: location table=\d+ records=(\d+)$/ =~ @data.shift
        records = Hash.new
        aor = ''
        @data.each do |r|
          if /\tAOR:: (?<peer>.+)$/ =~ r
            aor = peer
            records[aor] = Hash.new
          end
          if /^\t{2,3}(?<key>[^:]+):: (?<val>.*)$/ =~ r
            records[aor][key] = val if aor
          end
        end
        records
      end
    end

    class InvalidResponseData < Exception;end
    class EmptyResponseData < Exception;end
  end
end
