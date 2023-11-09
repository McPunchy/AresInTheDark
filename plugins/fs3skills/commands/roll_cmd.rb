module AresMUSH

  module FS3Skills
    class RollCmd
      include CommandHandler
      
      attr_accessor :name, :roll_str, :private_roll, 
                    :fortune_roll, :information_roll, :downtime_roll, 
                    :controlled_roll, :risky_roll, :desperate_roll, 
                    :standard_effect, :great_effect, :limited_effect, 
                    :mod_push, :mod_devil, :mod_assist,
                    :resist_roll,
                    :group_roll

      def parse_args
        if (cmd.args =~ /\//)
          args = cmd.parse_args(ArgParser.arg1_slash_arg2)          
          self.name = titlecase_arg(args.arg1)
          self.roll_str = titlecase_arg(args.arg2)
        else
          self.name = enactor_name        
          self.roll_str = titlecase_arg(cmd.args)
        end
      
        # The most haphazard way to parse switches ever
        if cmd.switch.nil?
          client.emit_failure t('fs3skills.roll_type_not_specified')
          return
        end
        switches = cmd.switch.split("/")
        switch_counts = {
          "private" => 0,
          "fortune" => 0,
          "information" => 0,
          "downtime" => 0,
          "controlled" => 0,
          "risky" => 0,
          "desperate" => 0,
          "standard" => 0,
          "great" => 0,
          "limited" => 0,
          "push" => 0,
          "devil" => 0,
          "assist" => 0,
          "resist" => 0,
          "group" => 0,
        }
        if switches.empty?
          client.emit_failure t('fs3skills.roll_type_not_specified')
          return
        end
        switches.each do |switch|
          if switch_counts.has_key?(switch)
           switch_counts[switch] += 1
          else
            client.emit_failure t('fs3skills.roll_type_not_specified')
            return
          end
        end
        if switch_counts["controlled"] + switch_counts["risky"] + switch_counts["desperate"] > 1
          client.emit_failure t('fs3skills.one_roll_position')
          return
        end
        if (switch_counts["controlled"] + switch_counts["risky"] + switch_counts["desperate"] > 0) && (switch_counts["standard"] + switch_counts["great"] + switch_counts["limited"] == 0)
          client.emit_failure t('fs3skills.effect_not_specified')
          return
        end
        if switch_counts["fortune"] + switch_counts["information"] + switch_counts["downtime"] > 1
          client.emit_failure t('fs3skills.only_one_roll_type')
          return
        end
        if (switch_counts["controlled"] + switch_counts["risky"] + switch_counts["desperate"] > 0) && (switch_counts["fortune"] + switch_counts["information"] + switch_counts["downtime"] > 0)
          client.emit_failure t('fs3skills.not_both_roll_types')
          return
        end

        # oh right I should define these switches
        self.private_roll = switches.include?("private")
        self.fortune_roll = switches.include?("fortune")
        self.information_roll = switches.include?("information")
        self.downtime_roll = switches.include?("downtime")
        self.controlled_roll = switches.include?("controlled")
        self.risky_roll = switches.include?("risky")
        self.desperate_roll = switches.include?("desperate")
        self.standard_effect = switches.include?("standard")
        self.great_effect = switches.include?("great")
        self.limited_effect = switches.include?("limited")
        self.mod_push = switches.include?("push")
        self.mod_devil = switches.include?("devil")
        self.mod_assist = switches.include?("assist")
        self.resist_roll = switches.include?("resist")
        self.group_roll = switches.include?("group")
      end
          
      
      def required_args
        [ self.name, self.roll_str ]
      end
      
      def handle
        char = Character.named(self.name)
        if (char)
          die_result = FS3Skills.parse_and_roll(char, self.roll_str)
          
        elsif (self.roll_str.is_integer?)
          die_result = FS3Skills.parse_and_roll(enactor, self.roll_str)
        else
          die_result = nil
        end
      
        if !die_result
          client.emit_failure t('fs3skills.unknown_roll_params')
          return
        end
        # experiment to see if I can at least shrink down message amounts here.
        roll_position = ""
        roll_effect = ""
        roll_type = ""
        if controlled_roll
          roll_position = "controlled"
        elsif risky_roll
          roll_position = "risky"
        elsif desperate_roll
          roll_position = "desperate"
        end
        if standard_effect
          roll_effect = "standard"
        elsif great_effect
          roll_effect = "great"
        elsif limited_effect
          roll_effect = "limited"
        end
        if fortune_roll
          roll_type = "fortune"
        elsif information_roll
          roll_type = "information"
        elsif downtime_roll
          roll_type = "downtime"
        elsif resist_roll
          roll_type = "resist"
        end
        success_level = FS3Skills.get_success_level(die_result)
        success_title = FS3Skills.get_success_title(success_level)
        nodice =FS3Skills.instance_variable_get(:@nodice)

        message = ""

       if nodice
         message += t('fs3skills.nodice_roll_prefix')
       end

       if roll_type.present?
          message += t('fs3skills.other_roll_result',
          :name => char ? char.name : "#{self.name} (#{enactor_name})",
          :roll => self.roll_str,
          :dice => FS3Skills.print_dice(die_result),
          :success => success_title,
          :type => roll_type,
         )
       elsif roll_position.present?
          message += t("fs3skills.action_roll_result",
            :name => char ? char.name : "#{self.name} (#{enactor_name})",
            :roll => self.roll_str,
            :dice => FS3Skills.print_dice(die_result),
            :success => success_title,
            :position => roll_position,
            :effect => roll_effect,
          )
       else
          client.emit_failure t('fs3skills.roll_type_not_specified1')
          return
       end

       if group_roll
          message += " (Group Roll.)"
        end

       if mod_push
         message += " (Push used.)"
       end
      
       if mod_assist
         message += " (Assisted.)"
       end
      
       if mod_devil
         message += " (Devil's Bargain Taken.)"
       end
      
        FS3Skills.emit_results message, client, enactor_room, self.private_roll
      end
    end
  end
end
