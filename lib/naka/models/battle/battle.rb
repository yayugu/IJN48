module Naka
  module Models
    module Battle
      class Battle
        attr_accessor :completed, :enemy_ids, :enemy_hps, :fleet_hps

        def completed? ; @completed ; end

        def fdam_and_edam(stage, now_hps)
          [:api_fdam, :api_edam].each_with_index do |key, fleet_index|
            stage[key].each_with_index do |dam, index|
              now_hps[6 * fleet_index + index] -= dam  if dam > 0
            end
          end
          now_hps
        end

        def self.from_api(response)
          battle = new
          data = response[:api_data]
          max_hps = data[:api_maxhps]
          now_hps = data[:api_nowhps]
          battle.completed = data[:api_midnight_flag] == 0
          battle.enemy_ids = data[:api_ship_ke].reject{|x| x == -1 }
          fleet_max_hps = max_hps[1, 6].reject{|x| x == -1}
          enemy_max_hps = max_hps[7, 6].reject{|x| x == -1}

          if data[:api_kouku]
            if key = data[:api_kouku][:api_stage3]
              now_hps = battle.fdam_and_edam(key, now_hps)
            end
          end
          if key = data[:api_opening_atack]
            now_hps = battle.fdam_and_edam(key, now_hps)
          end
          if key = data[:api_raigeki]
            now_hps = battle.fdam_and_edam(key, now_hps)
          end

          if data[:api_hougeki]
            data[:api_hougeki][:api_df_list].zip(data[:api_hougeki][:api_damage]).each do |fire|
              unless fire.first == -1
                now_hps[fire.first.first] -= fire.last.select{|x| x > 0}.sum
              end
            end
          end

          [:api_hougeki1, :api_hougeki2].each do |key|
            if data[key]
              data[key][:api_df_list].zip(data[key][:api_damage]).each do |fires|
                unless fires.first == -1
                  fires.first.zip(fires.last).each do |fire|
                    now_hps[fire.first] -= fire.last
                  end
                end
              end
            end
          end

          data.keys

          fleet_current_hps = now_hps[1, fleet_max_hps.length]
          battle.fleet_hps = fleet_current_hps.map{|x| [0, x.ceil].max}.zip(fleet_max_hps)

          enemy_current_hps = now_hps[7, enemy_max_hps.length]
          battle.enemy_hps = enemy_current_hps.map{|x| [0, x.ceil].max}.zip(enemy_max_hps)
          battle
        end
      end
    end
  end
end
