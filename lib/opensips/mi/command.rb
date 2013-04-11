module Opensips
  module MI
    class Command
      def method_missing(m, *args, &block)  
        params = args.shift || []
        params = Array[params] unless params.is_a?(Array)
        response = command 'which'
        raise NoMethodError, 
          "Method #{m} does not exists" unless response.data.include?(m.to_s)
        command m.to_s, params
      end
    end
  end
end
