module Opensips
  module MI
    class Response
      attr_reader :code, :success, :message
      attr_reader :rawdata # raw data array
      attr_reader :result  # formatted data

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
        #data.pop if @success
        @rawdata = data
        @result = nil
      end
      
      # Parse user locations records to Hash
      def ul_dump
        res = {}
        aor = nil
        contact = nil
        
        @rawdata.each do |r|
          next if r.start_with?("Domain")
          r = r.strip
          key, val = r.split(":: ")
          
          if key == "AOR"
            aor = val
            res[aor] = []
            next
          elsif key == "Contact"
            contact = {}
            res[aor] << contact
          end
          
          contact[key.gsub(?-, ?_).downcase.to_sym] = val
        end
        
        @result = res
        self
      end

      # returns struct
      def uptime
        res = Hash.new
        @rawdata.each do |r|
          next if /^Now::/ =~ r
          if /^Up since:: [^\s]+ (?'mon'[^\s]+)\s+(?'d'\d+) (?'h'\d+):(?'m'\d+):(?'s'\d+) (?'y'\d+)/ =~ r
            res[:since] = Time.local(y,mon,d,h,m,s)
          end
          if /^Up time:: (?'sec'\d+) / =~ r
            res[:uptime] = sec.to_i
          end
        end
        @result = OpenStruct.new res
        self
      end

      # returns struct
      def cache_fetch
        res = Hash.new
        @rawdata.each do |r|
          if /^(?'label'[^=]+)=\s+\[(?'value'[^\]]+)\]/ =~ r
            label.strip!
            res[label.to_sym] = value
          end
        end
        @result = OpenStruct.new res
        self
      end
      
      # returns Array of registered contacts
      def ul_show_contact
        res = {}
        aor = nil
        contact = nil
        
        @rawdata.each do |r|
          r = r.strip
          key, val = r.split(":: ")
          
          if key == "AOR"
            aor = val
            res[aor] = []
            next
          elsif key == "Contact"
            contact = {}
            res[aor] << contact
          end
          
          contact[key.gsub(?-, ?_).downcase.to_sym] = val
        end
        
        @result = res
        self
      end

      # returns hash of dialogs
      def dlg_list
        # parse dialogs information into array
        # assuming new block always starts with "dialog::  hash=..."
        calls, key = Hash.new, nil
        @rawdata.each do |l|
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
        @result = calls
        self
      end

      def dr_gw_status
        return self if @rawdata.empty?
        if /\AEnabled::\s+(?<status>yes|no)/ =~ @rawdata[0]
          self.class.send(:define_method, :enabled, proc{status.eql?('yes')})
          return self
        end
        @result = dr_gws_hash
        self
      end
      
      # returns array containing list of opensips processes
      def ps
        processes = []
        @rawdata.each do |l|
          l.slice! "Process::  "
          h = {}
          
          l.split(" ", 3).each do |x| 
            key, val = x.split("=", 2)
            h[key.downcase.to_sym] = val
          end
          
          processes << OpenStruct.new(h)
        end
        
        @result = processes
        self
      end

      private
       def dr_gws_hash
         Hash[
           @rawdata.map do |gw|
             if /\AID::\s+(?<id>[^\s]+)\s+IP=(?<ip>[^:\s]+):?(?<port>\d+)?\s+Enabled=(?<status>yes|no)/ =~ gw
               [id, {
                 enabled: status.eql?('yes'),
                 ipaddr: ip,
                 port: port
               }]
             end
           end
         ]
       end

    end # END class

    class InvalidResponseData < Exception;end
    class EmptyResponseData < Exception;end
  end
end
