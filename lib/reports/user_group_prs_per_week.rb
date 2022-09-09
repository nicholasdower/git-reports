require_relative 'report'

class UserGroupPrsPerWeek < Report
  def initialize(config)
    super
    @prs_per_week = {}
  end

  def on_day(day, prs, commits)
    @config[:user_groups].each do |name, user_group|
      week = (day - day.wday).strftime('%Y-%m-%d')
      @prs_per_week[name] ||= {}
      @prs_per_week[name][week] ||= {}

      user_group.each do |user|
        user_prs = prs.count { |pr| pr['user']['login'].downcase == user.downcase }
        @prs_per_week[name][week][user] ||= 0
        @prs_per_week[name][week][user] += user_prs
        @prs_per_week[name][week]['total'] ||= 0
        @prs_per_week[name][week]['total'] += user_prs
      end
    end
  end

  def on_done
    @config[:user_groups].each do |name, user_group|
      open("reports/#{@config[:name]}/#{name.downcase}_user_group_prs_per_week.tsv", 'w') do |out|
        if @config[:user_breakdown]
          out.puts (['week'] + user_group + ['total']).join("\t")
        else
          out.puts "week\ttotal"
        end
        @prs_per_week[name].each do |week, prs_per_user|
          values = []

          if @config[:user_breakdown]
            values.concat(user_group.map { |user| prs_per_user[user] })
          end
          values << prs_per_user['total']
          line = "#{week}\t#{values.join("\t")}"
          out.puts "#{line}"
        end
      end
    end
  end

  def chart_config
    @config[:user_groups].each_with_index.map do |(name, user_group), index|
      {
        type: "line",
        name: "#{name} User Group Pull Requests Per Week",
        group: "#{name} User Group",
        group_sort: index + 1,
        options: {
          hAxis: { title: 'Week' },
          vAxis: { title: 'Pull Requests' }
        },
        columns: [
          { type: 'date', label: 'Week' },
          { type: 'number', label: 'PRs' }
        ],
        rows: @prs_per_week[name].map { |week, prs_per_user| [week, prs_per_user['total']] }
      }
    end
  end
end

Report.add(UserGroupPrsPerWeek)
