require_relative 'report'

class TeamPrsPerWeek < Report
  def initialize(config)
    super
    @prs_per_week = {}
  end

  def on_day(day, prs, commits)
    @config[:teams].each do |name, team|
      week = (day - day.wday).strftime('%Y-%m-%d')
      @prs_per_week[team] ||= {}
      @prs_per_week[team][week] ||= {}

      team.each do |user|
        user_prs = prs.count { |pr| pr['user']['login'].downcase == user.downcase }
        @prs_per_week[team][week][user] ||= 0
        @prs_per_week[team][week][user] += user_prs
        @prs_per_week[team][week]['total'] ||= 0
        @prs_per_week[team][week]['total'] += user_prs
      end
    end
  end

  def on_done
    @config[:teams].each do |name, team|
      open("reports/#{@config[:name]}/#{name.downcase}_prs_per_week.tsv", 'w') do |out|
        if @config[:user_breakdown]
          out.puts (['week'] + team + ['total']).join("\t")
        else
          out.puts "week\ttotal"
        end
        @prs_per_week[team].each do |week, prs_per_user|
          values = []

          if @config[:user_breakdown]
            values.concat(team.map { |user| prs_per_user[user] })
          end
          values << prs_per_user['total']
          line = "#{week}\t#{values.join("\t")}"
          out.puts "#{line}"
        end
      end
    end
  end

  def chart_config
    @config[:teams].map do |name, team|
      {
        name: "#{name} Pull Requests Per Week",
        options: {
          hAxis: { title: 'Week' },
          vAxis: { title: 'Pull Requests' }
        },
        columns: [
          { type: 'date', label: 'Week' },
          { type: 'number', label: 'PRs' }
        ],
        rows: @prs_per_week[team].map { |week, prs_per_user| [week, prs_per_user['total']] }
      }
    end
  end
end

Report.add(TeamPrsPerWeek)
