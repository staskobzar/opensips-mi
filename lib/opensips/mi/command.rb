module Opensips
  module MI
    class Command
      def method_missing(md, *args, &block)  
        params = args.shift || []
        params = Array[params] unless params.is_a?(Array)
        response = command 'which'
        raise NoMethodError, 
          "Method #{md} does not exists" unless response.data.include?(md.to_s)
        response = command md.to_s, params
        # return special helper output if exists
        return false unless response.success
        if response.respond_to?(md)
          response.send md
        else
          response
        end
      end
    end
  end
end
