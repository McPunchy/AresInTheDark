module AresMUSH
  module FS3Skills
    
    def self.dice_to_roll_for_ability(char, roll_params)
      ability = roll_params.ability
      modifier = roll_params.modifier || 0

      if ("#{ability}".is_integer?)
        return "#{ability}".to_i + modifier
      end
      
      linked_attr = roll_params.linked_attr || FS3Skills.get_linked_attr(ability)
      ability_type = FS3Skills.get_ability_type(ability)
      skill_rating = FS3Skills.ability_rating(char, ability)
      
      # Language and advantage shouldn't be rolled, but can be to avoid problems. One dice per dot.
      if (ability_type == :language || ability_type == :advantage)
        skill_rating = skill_rating * 1
      # Backgrounds should not be rolled but can at one dice per dot. Unknown skills give 0 dice.
      elsif (ability_type == :background)
        skill_rating = skill_rating == 0 ? 1 : skill_rating * 1
      elsif (ability_type == :attribute && !linked_attr)
        skill_rating = 0
        linked_attr = ability
      end
      
      if ability_type == :attribute
        apt_rating = linked_attr ? FS3Skills.ability_rating(char, linked_attr) : 0
      else
        apt_rating = 0
      end
      
      dice = skill_rating + apt_rating + modifier
      Global.logger.debug "#{char.name} rolling #{ability} mod=#{modifier} skill=#{skill_rating} linked_attr=#{linked_attr} apt=#{apt_rating}"
      
      dice
    end
    
    
    # Takes a roll string, like Athletics+Body+2, or just Athletics, parses it to figure
    # out the pieces, and then makes the roll. No +2 bonuses or anything like that.
    def self.parse_and_roll(char, roll_str)
      if (roll_str.is_integer?)
        dice = (roll_str.to_i) + 0
        die_result = FS3Skills.roll_dice(dice)
      else
        roll_params = FS3Skills.parse_roll_params roll_str
        if (!roll_params)
          return nil
        end
        die_result = FS3Skills.roll_ability(char, roll_params)
      end
      die_result
    end
    
    # Parses a roll string in the form Ability+Attr(+ or -)Modifier, where
    # everything except "Ability" is optional.
    # Can also do Attr+Attr or Attr+Attr.
    def self.parse_roll_params(str)
      match = /^(?<ability>[^\+\-]+)\s*(?<linked_attr>[\+]\s*[A-Za-z\s]+)?\s*(?<modifier>[\+\-]\s*\d+)?$/.match(str)
      return nil if !match
      
      ability = match[:ability].strip
      modifier = match[:modifier].nil? ? 0 : match[:modifier].gsub(/\s+/, "").to_i
      linked_attr = match[:linked_attr].nil? ? nil : match[:linked_attr][1..-1].strip
      
      # If they entered the attr and ability backwards, swap them
      ability_type = FS3Skills.get_ability_type(ability)
      if (ability_type == :attribute && linked_attr)
        tmp = ability
        ability = linked_attr
        linked_attr = tmp
      end
      
      if (linked_attr)
        ability_type = FS3Skills.get_ability_type(linked_attr)
        if (ability_type != :attribute)
          return nil
        end
      end
      
      return RollParams.new(ability, modifier, linked_attr)
    end
    
  end
end