require_relative 'report'

class UserGroupPrsPerMonth < Report
  def initialize(config)
    super
    @prs_per_month = {}
  end

  def on_day(day, prs, commits)
    @config[:user_groups].each do |name, user_group|
      month = (day - day.mday + 1).strftime('%Y-%m-%d')
      @prs_per_month[name] ||= {}
      @prs_per_month[name][month] ||= {}

      user_group.each do |user|
        user_prs = prs.count { |pr| pr['user']['login'].downcase == user.downcase }
        @prs_per_month[name][month][user] ||= 0
        @prs_per_month[name][month][user] += user_prs
        @prs_per_month[name][month]['total'] ||= 0
        @prs_per_month[name][month]['total'] += user_prs
      end
    end
  end

  def on_done
    @config[:user_groups].each do |name, user_group|
      open("reports/#{@config[:name]}/#{name.downcase}user_group_prs_per_month.tsv", 'w') do |out|
        if @config[:user_breakdown]
          out.puts (['month'] + user_group + ['total']).join("\t")
        else
          out.puts "month\ttotal"
        end
        @prs_per_month[name].each do |month, prs_per_user|
          values = []

          if @config[:user_breakdown]
            values.concat(user_group.map { |user| prs_per_user[user] })
          end
          values << prs_per_user['total']
          line = "#{month}\t#{values.join("\t")}"
          out.puts "#{line}"
        end
      end
    end
  end

  def chart_config
    @config[:user_groups].each_with_index.map do |(name, user_group), index|
      {
        type: "line",
        name: "#{name} User Group Pull Requests Per Month",
        group: "#{name} User Group",
        group_sort: index + 1,
        options: {
          hAxis: { title: 'Month' },
          vAxis: { title: 'Pull Requests' }
        },
        columns: [
          { type: 'date', label: 'Month' },
          { type: 'number', label: 'PRs' }
        ],
        rows: @prs_per_month[name].map { |month, prs_per_user| [month, prs_per_user['total']] }
      }
    end
  end
end

Report.add(UserGroupPrsPerMonth)
