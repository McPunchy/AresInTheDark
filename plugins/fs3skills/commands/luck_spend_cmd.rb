module AresMUSH
  module FS3Skills
    class LuckSpendCmd
      include CommandHandler
      
      attr_accessor :reason, :num_points

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_optional_arg2)
        self.reason = trim_arg(args.arg1)
        self.num_points = args.arg2 ? Integer(args.arg2) : 1
      end

      def required_args
        [ self.reason ]
      end
      
      
      def handle
        FS3Skills.spend_luck(enactor, self.reason, enactor_room.scene, self.num_points)
      end
    end
  end
end