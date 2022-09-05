require_relative 'report'

class TeamPrsPerWeek < Report
  def generate(config, prs_per_day)
    config[:teams].each.each do |name, team|
      open("reports/#{config[:name]}/#{name}_prs_per_week.tsv", 'w') do |out|
        prs_per_week = {}

        prs_per_day.each do |day, prs|
          week = (day - day.wday).strftime('%Y-%m-%d')
          prs_per_week[week] ||= {}
          team.each do |user|
            user_prs = prs.select { |pr| pr['user']['login'].downcase == user }
            prs_per_week[week][user] ||= []
            prs_per_week[week][user].concat(user_prs)
            prs_per_week[week]['total'] ||= []
            prs_per_week[week]['total'].concat(user_prs)
          end
        end

        if config[:user_breakdown]
          out.puts (['week'] + team + ['total']).join("\t")
        else
          out.puts "week\ttotal"
        end
        prs_per_week.each do |week, prs_per_user|
          values = []

          if config[:user_breakdown]
            values.concat(team.map { |user| prs_per_user[user].size })
          end
          values << prs_per_user['total'].size
          line = "#{week}\t#{values.join("\t")}"
          out.puts "#{line}"
        end
      end
    end
  end
end

Report.add(TeamPrsPerWeek)
