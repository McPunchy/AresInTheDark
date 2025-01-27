module AresMUSH

  module FS3Skills
    class RaiseAbilityCmd
      include CommandHandler
      
      attr_accessor :name

      def parse_args
        self.name = titlecase_arg(cmd.args)
      end

      def required_args
        [ self.name ]
      end
      
      def check_chargen_locked
        Chargen.check_chargen_locked(enactor)
      end
      
      def handle
        current_rating = FS3Skills.ability_rating(enactor, self.name)
        mod = cmd.root_is?("raise") ? 1 : -1
        new_rating = current_rating + mod
        
        error = FS3Skills.check_rating(self.name, new_rating)
        if (error)
          client.emit_failure error
          return
        end
      
        error = FS3Skills.set_ability(enactor, self.name, new_rating)
        if (error)
          client.emit_failure error
        else
          client.emit_success FS3Skills.ability_raised_text(enactor, self.name)

          # If the ability is an action skill, update the rating of the linked attribute
          ability_type = FS3Skills.get_ability_type(self.name)
          if ability_type == :action
             linked_attr = FS3Skills.get_linked_attr(self.name)
             FS3Skills.update_attribute_rating(enactor, linked_attr)
           end
        end
      end
    end
  end
end
