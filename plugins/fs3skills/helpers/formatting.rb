module AresMUSH
  module FS3Skills
    
    def self.print_dice(dice)
      nodice = FS3Skills.instance_variable_get(:@nodice)
      if (nodice)
        dice.sort.map.with_index { |d, i| i == 0 ? (d >= FS3Skills.success_target_number ? "[%xg #{d}%xn]" : (d >= FS3Skills.complication_target_number ? "[%xy #{d}%xn]" : "[%xr #{d}%xn]")) : (d >= FS3Skills.success_target_number ? "%xg#{d}%xn" : (d >= FS3Skills.complication_target_number ? "%xy#{d}%xn" : "%xr#{d}%xn")) }.join(" ")
      else
        dice.sort.reverse.map.with_index { |d, i| i == 0 ? (d >= FS3Skills.success_target_number ? "[%xg #{d}%xn]" : (d >= FS3Skills.complication_target_number ? "[%xy #{d}%xn]" : "[%xr #{d}%xn]")) : (d >= FS3Skills.success_target_number ? "%xg#{d}%xn" : (d >= FS3Skills.complication_target_number ? "%xy#{d}%xn" : "%xr#{d}%xn")) }.join(" ")
      end
    end

    
    
    def self.get_success_title(success_level)
      case success_level
      when -1
        t('fs3skills.embarrassing_failure')
      when 0
        t('fs3skills.failure')
      when 1
        t('fs3skills.success')
      when 2..99
        t('fs3skills.amazing_success')
      else
        raise "Unexpected roll result: #{success_level}"
      end
    end
    
    def self.opposed_result_title(name1, successes1, name2, successes2)
      delta = successes1 - successes2
      
      if (successes1 <=0 && successes2 <= 0)
        return t('fs3skills.opposed_both_fail')
      end
      
      case delta
      when 3..99
        return t('fs3skills.opposed_crushing_victory', :name => name1)
      when 2
        return t('fs3skills.opposed_victory', :name => name1)
      when 1
        return t('fs3skills.opposed_marginal_victory', :name => name1)
      when 0
        return t('fs3skills.opposed_draw')
      when -1
        return t('fs3skills.opposed_marginal_victory', :name => name2)
      when -2
        return t('fs3skills.opposed_victory', :name => name2)
      when -99..-3
        return t('fs3skills.opposed_crushing_victory', :name => name2)
      else
        raise "Unexpected opposed roll result: #{successes1} #{successes2}"
      end
    end
    
    
  end
end
