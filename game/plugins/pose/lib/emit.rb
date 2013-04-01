module AresMUSH
  module Pose
    class Emit
      include AresMUSH::Plugin

      def after_initialize
        @client_monitor = container.client_monitor
      end
      
      def want_command?(cmd)
        cmd.root_is?("emit")
      end
      
      def on_command(client, cmd)
        @client_monitor.emit_all Formatter.parse_pose(client.name, "\\#{cmd.args}")
      end
    end
  end
end
