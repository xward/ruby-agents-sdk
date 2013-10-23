module ProtocolGenerator

  module Models

    class Shot

      attr_accessor :message_type, :name, :id
      attr_reader :next_shots

      def initialize(params = {})
        self.way = params[:way]
        @name = params[:name]
        @message_type = params[:message_type] # Models::Message
        @callbacks = {}
        [:received_callback, :ack_timeout_callback, :cancel_callback, :response_timeout_callback, :send_timeout_callback, :server_nack_callback].each do |cb|
          @callbacks[cb] = params[cb] if params[cb] # string
        end
        @next_shots = params[:next_shots] || []
        @id = params[:id]
      end

      # @return `true` if it this shot does not have any "next shots" defined
      def last?
        @next_shots.size == 0
      end

      def way=(new_way)
        if new_way != :to_server && new_way != :to_device
          raise ArgumentError.new("A shot way can only be :to_server or :to_device, got #{way}")
        end
        unless @message_type.nil?
          if @message_type.way != new_way
            raise ArgumentError.new("Shot way set to #{new_way} while its message type has 'way' set to #{@message_type.way}")
          end
        end
        @way = new_way
      end

      def way
        @way
      end

      def next_shots=(next_shots)
        unless next_shots.is_a? Array # to prevent next_shots from being nil
          raise ArgumentError.new("Next shots can't be nil (but can be an empty array)")
        end
        @next_shots = next_shots
      end

      # @param [Symbol] cb a specific callback (as :received_callback)
      def has_callback?(cb)
        @callbacks.has_key?(cb)
      end

      # @param [Symbol] cb a callback
      # @return [String] the callback name (may be nil)
      def callback(cb)
        @callbacks[cb]
      end

    end

  end

end