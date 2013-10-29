module Opensips
  module MI
    class Command
      EVENTNOTIFY = {
        # Aastra
        aastra_check_cfg:       'check-sync',
        aastra_xml:             'aastra-xml',
        # Digium
        digium_check_cfg:       'check-sync',
        # Linksys
        linksys_cold_restart:   'reboot_now',
        linksys_warm_restart:   'restart_now',
        # Polycom
        polycom_check_cfg:      'check-sync',
        # Sipura
        sipura_check_cfg:       'resync',
        sipura_get_report:      'report',
        # Snom
        snom_check_cfg:         'check-sync;reboot=false',
        snom_reboot:            'check-sync;reboot=true',
        # Cisco
        cisco_check_cfg:        'check-sync',
        # Avaya
        avaya_check_cfg:        'check-sync',
      }

      # Interface to mi methods direct call
      def method_missing(md, *params, &block)  
        response = command 'which'
        raise NoMethodError, 
          "Method #{md} does not exists" unless response.rawdata.include?(md.to_s)
        response = command md.to_s, params
        # return special helper output if exists
        return response unless response.success
        if response.respond_to?(md)
          response.send md
        else
          response
        end
      end

      # = Interface to t_uac_dlg function of transaction (tm) module
      # Very cool method from OpenSIPs. Can generate and send SIP request method to destination.
      # Example of usage:
      #   - Send NOTIFY with special Event header to force restart SIP phone (equivalent of ASterisk's "sip notify peer")
      #   - Send PUBLISH to trigger device state change notification
      #   - Send REFER to transfer call
      #   - etc., etc., etc.
      #
      # == Headers
      # Headers parameter "hf" is a hash of headers of format:
      #   header-name => header-value
      # Example:
      #   hf["From"] => "Alice Liddell <sip:alice@wanderland.com>;tag=843887163"
      #
      # Special "nl" header with any value is used to input additional "\r\n". This is
      # useful, for example, for message-summary event to separate application body. This is
      # because t_uac_dlg expect body parameter as xml only.
      #
      # Thus, using multiple headers with same header-name is not possible with header hash.
      # However, it is possible to use multiple header-values comma separated (rfc3261, section 7.3.1):
      #   hf["Route"] => "<sip:alice@atlanta.com>, <sip:bob@biloxi.com>"
      # Is equivalent to:
      #   Route: <sip:alice@atlanta.com>
      #   Route: <sip:bob@biloxi.com>
      #
      # If there is headers To and From not found, then exception ArgumentError is raised. Also if
      # body part present, Content-Type and Content-length are also mandatory and exception is raised.
      #
      # == Parameters
      #   method:     SIP request method (NOTIFY, PUBLISH etc)
      #   ruri:       Request URI, ex.: sip:555@10.0.0.55:5060
      #   hf:         Headers array. Additional headers will be added to request. 
      #               At least "From" and "To" headers must be specify
      #   nhop:       Next hop SIP URI (OBP); use "." if no value.
      #   socket:     Local socket to be used for sending the request; use "." if no value. Ex.: udp:10.130.8.21:5060
      #   body:       (optional, may not be present) request body (if present, requires the "Content-Type" and "Content-length" headers)
      #
      def uac_dlg method, ruri, hf, next_hop = ?., socket = ?., body = nil
        mandatory_hf = Array['To', 'From']
        mandatory_hf += ['Content-Type'] unless body.nil?
        mandatory_hf.map{|h|h.downcase}.each do |n|
          raise ArgumentError, 
            "Missing mandatory header #{n.capitalize}" unless hf.keys.map{|h| h.downcase}.include?(n)
        end
        # compile headers to string
        headers = hf.map{|name,val| name.eql?("nl") ? "" : "#{name}: #{val}"}.join "\r\n"
        headers << "\r\n"
        
        # set_header is a hack for xmlrpc which fails if headers are quoted
        params = [method, ruri, next_hop, socket, set_header(headers)]
        params << body unless body.nil?
        # send it and return Response
        command 't_uac_dlg', params
      end

      # = NOTIFY check-sync like event
      # NOTIFY Events to restart phone, force configuration reload or 
      # report for some SIP IP phone models. 
      # The events list was taken from Asterisk configuration file (sip_notify.conf)
      # Note that SIP IP phones usually should be configured to accept special notify
      # event to reboot. For example, Polycom configuration option to enable special
      # event would be:
      #   voIpProt.SIP.specialEvent.checkSync.alwaysReboot="1"
      #
      # This function will generate To/From/Event headers. Will use random tag for 
      # From header. 
      # *NOTE*: This function will not generate To header tag. This is not complying with
      # SIP protocol specification (rfc3265). NOTIFY must be part of a subscription 
      # dialog. However, it works for the most of the SIP IP phone models.
      # == Parameters
      #   - uri:    Valid client contact URI (sip:alice@10.0.0.100:5060). 
      #             To get client URI use *ul_show_contact => contact* function
      #   - event:  One of the events from EVENTNOTIFY constant hash
      #   - hf:     Header fields. Add To/From header fields here if you do not want them 
      #             to be auto-generated. Header field example:
      #             hf['To'] => '<sip:alice@wanderland.com>'
      #
      def event_notify uri, event, hf = {}
        raise ArgumentError,
          "Invalid notify event: #{event.to_s}" unless EVENTNOTIFY.keys.include?(event)
        hf['To'] = "<#{uri}>" unless hf.keys.map{|k|k.downcase}.include?('to')
        hf['From'] = "<#{uri}>;tag=#{SecureRandom.hex}" unless hf.keys.map{|k|k.downcase}.include?('from')
        hf['Event'] = EVENTNOTIFY[event]
        
        uac_dlg "NOTIFY", uri, hf
      end

      # = Presence MWI
      # Send message-summary NOTIFY Event to update phone voicemail status.
      #
      # == Parameters
      #   - uri:      Request URI (sip:alice@wanderland.com:5060)
      #               To get client URI use *ul_show_contact => contact* function
      #   - vmaccount:Message Account value. Ex.: sip:*97@asterisk.com
      #   - new:      Number of new messages. If more than 0 then Messages-Waiting header
      #               will be "yes". Set to 0 to clear phone MWI
      #   - old:      (optional) Old messages
      #   - urg_new:  (optional) New urgent messages
      #   - urg_old:  (optional) Old urgent messages
      #
      def mwi_update uri, vmaccount, new, old = 0, urg_new = 0, urg_old = 0
        mbody = Hash[
          'Messages-Waiting'  => (new > 0 ? "yes" : "no"),
          'Message-Account'   => vmaccount,
          'Voice-Message'     => "#{new}/#{old} (#{urg_new}/#{urg_old})",
        ]
        hf = Hash[
          'To'                => "<#{uri}>",
          'From'              => "<#{uri}>;tag=#{SecureRandom.hex}",
          'Event'             => "message-summary",
          'Subscription-State'=> "active",
          'Content-Type'      => "application/simple-message-summary",
          'nl'                => "",
        ]

        uac_dlg "NOTIFY", uri, hf.merge(mbody)
      end

      private
        def set_header(header);"\"#{header}\"";end

        def host_valid? params
          raise ArgumentError,
            'Missing socket host' if params[:host].nil?
          raise ArgumentError,
            'Missing socket port' if params[:port].nil?
          Socket.getaddrinfo(params[:host], nil) rescue 
            raise SocketError, "Invalid host #{params[:host]}" 
          raise SocketError, 
            "Invalid port #{params[:port]}" unless (1..(2**16-1)).include?(params[:port])
          true
        end
      
    end
  end
end
