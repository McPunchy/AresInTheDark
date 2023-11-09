module AresMUSH
  module FS3Skills
    @nodice = false
    def self.success_target_number
      6
    end
    def self.complication_target_number
      4
    end
    
    # Makes an ability roll and returns the raw dice results.
    # Good for when you're doing a regular roll because you can show the raw dice and
    # use the other methods in this class to get the success level and title to display.
    def self.roll_ability(char, roll_params)
      dice = FS3Skills.dice_to_roll_for_ability(char, roll_params)
      roll = FS3Skills.roll_dice(dice)
      Global.logger.info "#{char.name} rolling #{roll_params} dice=#{dice} result=#{roll}"
      Achievements.award_achievement(char, "fs3_roll")
      roll
    end
    

        
    # Rolls a number of FS3 dice and returns the raw die results.
    def self.roll_dice(dice)
      if (dice > 30)
        Global.logger.warn "Attempt to roll #{dice} dice."
        # Hey if they're rolling this many dice they ought to succeed spectacularly.
        return [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8]
      end
      @nodice = false
      if dice == 0
        @nodice = true
        [1 + rand(6), 1 + rand(6)]
      else
        dice.times.collect { 1 + rand(6) }
      end
    end
    
    # Changed to define successes by highest die, not total successes. Complications added.
    def self.get_success_level(die_result)
      if @nodice
        highest_die = die_result.min
        successes = die_result.count {highest_die >= FS3Skills.success_target_number }
        return successes if (successes > 0)
        return 0 if (successes == 0) and (highest_die >= FS3Skills.complication_target_number )
        return -1
      else
        highest_die = die_result.max
        successes = die_result.count { |d| d >= FS3Skills.success_target_number }
        return successes if (successes > 0)
        return 0 if (successes == 0) and (highest_die >= FS3Skills.complication_target_number )
        return -1
      end
    end


    def self.emit_results(message, client, room, is_private)
      if (is_private)
        client.emit message
      else
        room.emit message
        channel = Global.read_config("fs3skills", "roll_channel")
        if (channel)
          Channels.send_to_channel(channel, message)
        end
        
        if (room.scene)
          Scenes.add_to_scene(room.scene, message)
        end
        
      end
      Global.logger.info "FS3 roll results: #{message}"
    end
    
    # Returns either { message: roll_result_message }  or  { error: error_message }
    def self.determine_web_roll_result(request, enactor)
      
      roll_str = request.args[:roll_string]
      vs_roll1 = request.args[:vs_roll1] || ""
      vs_roll2 = request.args[:vs_roll2] || ""
      vs_name1 = (request.args[:vs_name1] || "").titlecase
      vs_name2 = (request.args[:vs_name2] || "").titlecase
      pc_name = request.args[:pc_name] || ""
      pc_skill = request.args[:pc_skill] || ""
      risky_roll = request.args[:risky_roll] || false
      controlled_roll = request.args[:controlled_roll] || false
      desperate_roll = request.args[:desperate_roll] || false
      limited_effect = request.args[:limited_effect] || false
      standard_effect = request.args[:standard_effect] || false
      great_effect = request.args[:great_effect] || false
      fortune_roll = request.args[:fortune_roll] || false
      information_roll = request.args[:information_roll] || false
      downtime_roll = request.args[:downtime_roll] || false
      push_roll = request.args[:push_roll] || false
      resist_roll = request.args[:resist_roll] || false
      devil_roll = request.args[:devil_roll] || false
      groupaction_roll = request.args[:groupaction_roll] || false
      assist_roll = request.args[:assist_roll] || false

      
      # ------------------
      # VS ROLL
      # ------------------
      if (!vs_roll1.blank?)
        result = ClassTargetFinder.find(vs_name1, Character, enactor)
        model1 = result.target
        if (!model1 && !vs_roll1.is_integer?)
          vs_roll1 = "3"
        end
                              
        result = ClassTargetFinder.find(vs_name2, Character, enactor)
        model2 = result.target
        vs_name2 = model2 ? model2.name : vs_name2
                              
        if (!model2 && !vs_roll2.is_integer?)
          vs_roll2 = "3"
        end
        
        die_result1 = FS3Skills.parse_and_roll(model1, vs_roll1)
        die_result2 = FS3Skills.parse_and_roll(model2, vs_roll2)
        
        if (!die_result1 || !die_result2)
          return { error: t('fs3skills.unknown_roll_params') }
        end
        
        successes1 = FS3Skills.get_success_level(die_result1)
        successes2 = FS3Skills.get_success_level(die_result2)
          
        results = FS3Skills.opposed_result_title(vs_name1, successes1, vs_name2, successes2)
        
        message = t('fs3skills.opposed_roll_result', 
           :name1 => !model1 ? t('fs3skills.npc', :name => vs_name1) : model1.name,
           :name2 => !model2 ? t('fs3skills.npc', :name => vs_name2) : model2.name,
           :roll1 => vs_roll1,
           :roll2 => vs_roll2,
           :dice1 => FS3Skills.print_dice(die_result1),
           :dice2 => FS3Skills.print_dice(die_result2),
           :result => results)  

      # ------------------
      # PC ROLL
      # ------------------
      elsif (!pc_name.blank?)
        char = Character.find_one_by_name(pc_name)

        if (!char && !pc_skill.is_integer?)
          pc_skill = "3"
        end
        roll_position = ""
        roll_effect = ""
        roll_type = ""
        if (controlled_roll == 'true')
          roll_position = "controlled"
        elsif (risky_roll == 'true')
          roll_position = "risky"
        elsif (desperate_roll == 'true')
          roll_position = "desperate"
        end
        if (standard_effect == 'true')
          roll_effect = "standard"
        elsif (great_effect == 'true')
          roll_effect = "great"
        elsif (limited_effect == 'true')
          roll_effect = "limited"
        end
        if (fortune_roll == 'true')
          roll_type = "fortune"
        elsif (information_roll == 'true')
          roll_type = "information"
        elsif (downtime_roll == 'true')
          roll_type = "downtime"
        elsif (resist_roll == 'true')
          roll_type = "resist"
        end        
        roll = FS3Skills.parse_and_roll(char, pc_skill)
        roll_result = FS3Skills.get_success_level(roll)
        success_title = FS3Skills.get_success_title(roll_result)
        nodice = FS3Skills.instance_variable_get(:@nodice)

        message = ""
        
        if nodice
         message += t('fs3skills.nodice_roll_prefix')
        end

        if roll_type.present? && !roll_type.empty?
          message += t('fs3skills.other_roll_result',
          :name => char ? char.name : "#{pc_name} (#{enactor.name})",
          :roll => pc_skill,
          :dice => FS3Skills.print_dice(roll),
          :success => success_title,
          :type => roll_type
         )
        else roll_position.present? && !roll_position.empty?
          message += t("fs3skills.action_roll_result",
            :name => char ? char.name : "#{pc_name} (#{enactor.name})",
            :roll => pc_skill,
            :dice => FS3Skills.print_dice(roll),
            :success => success_title,
            :position => roll_position,
            :effect => roll_effect
          )
       end
       
       if push_roll == 'true'
         message += " (Push used.)"
       end
      
       if devil_roll == 'true'
         message += " (Devil's Bargain Taken.)"
       end
      
       if groupaction_roll == 'true'
         message += " (Group Roll.)"
       end
      
       if assist_roll == 'true'
         message += " (Assisted.)"
     end

          
      # ------------------
      # SELF ROLL
      # ------------------      
      else
        roll_position = ""
        roll_effect = ""
        roll_type = ""
        if (controlled_roll == 'true')
          roll_position = "controlled"
        elsif (risky_roll == 'true')
          roll_position = "risky"
        elsif (desperate_roll == 'true')
          roll_position = "desperate"
        else
          roll_position = ""
        end
        if (standard_effect == 'true')
          roll_effect = "standard"
        elsif (great_effect == 'true')
          roll_effect = "great"
        elsif (limited_effect == 'true')
          roll_effect = "limited"
        else
          roll_effect = ""
        end
        if (information_roll == 'true')
          roll_type = "information"
        elsif (fortune_roll == 'true')
          roll_type = "fortune"
        elsif (downtime_roll == 'true')
          roll_type = "downtime"
        elsif (resist_roll == 'true')
          roll_type = "resist"
        else
          roll_type = ""
        end        
        roll = FS3Skills.parse_and_roll(enactor, roll_str)
        roll_result = FS3Skills.get_success_level(roll)
        success_title = FS3Skills.get_success_title(roll_result)
        nodice = FS3Skills.instance_variable_get(:@nodice)

        message = ""
        if nodice
          message += t('fs3skills.nodice_roll_prefix')
        end

        if roll_position.present? && !roll_position.empty?
          message += t("fs3skills.action_roll_result",
            :name => enactor.name,
            :roll => roll_str,
            :dice => FS3Skills.print_dice(roll),
            :success => success_title,
            :position => roll_position,
            :effect => roll_effect
          )
        elsif roll_type.present? && !roll_type.empty?
          message += t('fs3skills.other_roll_result',
            :name => enactor.name,
            :roll => roll_str,
            :dice => FS3Skills.print_dice(roll),
            :success => success_title,
            :type => roll_type
          )
        end

        if push_roll == 'true'
          message += " (Push used.)"
        end

        if devil_roll == 'true'
          message += " (Devil's Bargain Taken.)"
        end

        if groupaction_roll == 'true'
          message += " (Group Roll.)"
        end 

        if assist_roll == 'true'
          message += " (Assisted.)"
        end

      end
      
      return { message: message }
    end
  end
end