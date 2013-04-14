require 'ostruct'

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

      # returns struct
      def uptime
        res = Hash.new
        @data.each do |r|
          next if /^Now::/ =~ r
          if /^Up since:: [^\s]+ (?'mon'[^\s]+)\s+(?'d'\d+) (?'h'\d+):(?'m'\d+):(?'s'\d+) (?'y'\d+)/ =~ r
            res[:since] = Time.local(y,mon,d,h,m,s)
          end
          if /^Up time:: (?'sec'\d+) / =~ r
            res[:uptime] = sec.to_i
          end
        end
        OpenStruct.new res
      end

      # returns struct
      def cache_fetch
        res = Hash.new
        @data.each do |r|
          if /^(?'label'[^=]+)=\s+\[(?'value'[^\]]+)\]/ =~ r
            label.strip!
            res[label.to_sym] = value
          end
        end
        OpenStruct.new res
      end
      
      # returns Array of registered contacts
      def ul_show_contact
        res = Array.new
        @data.each do |r|
          cont = Hash.new
          r.split(?;).each do |rec|
            if /^Contact:: (.*)$/ =~ rec
              cont[:contact] = $1
            else
              key,val = rec.split ?=
              cont[key.to_sym] = val
            end
          end
          res << cont
        end
        res
      end

      # returns hash of dialogs
      def dlg_list
        # parse dialogs information into array
        # assuming new block always starts with "dialog::  hash=..."
        calls, key = Hash.new, nil
        @data.each do |l|
          l.strip!
          if l.match(/^dialog::\s+hash=(.*)$/)
            key = $1
            calls[key] = Hash.new
            next
          end
          # building dialog array
          if l.match(/^([^:]+)::\s+(.*)$/)
            calls[key][$1.to_sym] = $2
          end
        end
        calls
      end

    end

    class InvalidResponseData < Exception;end
    class EmptyResponseData < Exception;end
  end
end
