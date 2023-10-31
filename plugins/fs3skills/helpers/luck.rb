module AresMUSH
  module FS3Skills
    def self.can_manage_luck?(actor)
      actor && actor.has_permission?("manage_abilities")
    end
    
    def self.modify_luck(char, amount)
      max_luck = Global.read_config("fs3skills", "max_luck")
      luck = char.luck + amount
      luck = [max_luck, luck].min
      luck = [0, luck].max
      char.update(fs3_luck: luck)
    end
    
    def self.spend_luck(char, reason, scene, num_points = 1)
      num_points = num_points.to_i
      Global.logger.info "num_points: #{num_points}"  # Add logging
      max_luck = Global.read_config("fs3skills", "max_luck")
      overlap = 0
      if num_points > char.luck
        overlap = num_points - char.luck
        char.update(fs3_luck: max_luck)
      else
        char.spend_luck(num_points)
      end
  
      if overlap > 0
       message = t('fs3skills.luck_point_spent_with_overlap', :name => char.name, :reason => reason, :count => num_points, :overlap => overlap.to_i)
      else
       message = t('fs3skills.luck_point_spent', :name => char.name, :reason => reason, :count => num_points)
      end

      if (scene)
        scene.room.emit_ooc message
        Scenes.add_to_scene(scene, message)
      else
        char.room.emit_ooc message
      end
      
      Achievements.award_achievement(char, "fs3_luck_spent")
      
      if (Global.read_config('fs3skills', 'job_on_luck_spend'))
        category = Jobs.system_category
        status = Jobs.create_job(category, t('fs3skills.luck_job_title', :name => char.name), message, Game.master.system_character)
        if (status[:job])
          Jobs.close_job(Game.master.system_character, status[:job])
        end
      end


      if overlap > 0
        Achievements.award_achievement(char, "fs3_trauma_gained")
        category = Jobs.system_category
        status = Jobs.create_job(category, t('fs3skills.trauma_job_title', :name => char.name), message, Game.master.system_character)
      end
      
      Global.logger.info "#{char.name} spent #{num_points} luck on #{reason}."
    end
  end
end
