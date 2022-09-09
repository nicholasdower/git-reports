require_relative 'report'

class TeamPrsPerMonth < Report
  def initialize(config)
    super
    @prs_per_month = {}
  end

  def on_day(day, prs, commits)
    @config[:teams].each do |name, team|
      month = (day - day.mday + 1).strftime('%Y-%m-%d')
      @prs_per_month[team] ||= {}
      @prs_per_month[team][month] ||= {}

      team.each do |user|
        user_prs = prs.count { |pr| pr['user']['login'].downcase == user.downcase }
        @prs_per_month[team][month][user] ||= 0
        @prs_per_month[team][month][user] += user_prs
        @prs_per_month[team][month]['total'] ||= 0
        @prs_per_month[team][month]['total'] += user_prs
      end
    end
  end

  def on_done
    @config[:teams].each do |name, team|
      open("reports/#{@config[:name]}/#{name.downcase}_prs_per_month.tsv", 'w') do |out|
        if @config[:user_breakdown]
          out.puts (['month'] + team + ['total']).join("\t")
        else
          out.puts "month\ttotal"
        end
        @prs_per_month[team].each do |month, prs_per_user|
          values = []

          if @config[:user_breakdown]
            values.concat(team.map { |user| prs_per_user[user] })
          end
          values << prs_per_user['total']
          line = "#{month}\t#{values.join("\t")}"
          out.puts "#{line}"
        end
      end
    end
  end

  def chart_config
    @config[:teams].map do |name, team|
      {
        name: "#{name} Pull Requests Per Month",
        options: {
          hAxis: { title: 'Month' },
          vAxis: { title: 'Pull Requests' }
        },
        columns: [
          { type: 'date', label: 'Month' },
          { type: 'number', label: 'PRs' }
        ],
        rows: @prs_per_month[team].map { |month, prs_per_user| [month, prs_per_user['total']] }
      }
    end
  end
end

Report.add(TeamPrsPerMonth)
