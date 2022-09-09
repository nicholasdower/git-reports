require_relative 'report'

class TopUsersLastWeek < Report
  def initialize(config)
    super
    @users = {}
    @min_day = Date.today - 8
  end

  def on_day(day, prs, commits)
    return if day < @min_day

    prs.each do |pr|
      unless bot_or_auto?(pr)
        login = pr['user']['login']
        @users[login] ||= 0
        @users[login] += 1
      end
    end
  end

  def on_done
    open("reports/#{@config[:name]}/top_users_last_week.tsv", 'w') do |out|
      out.puts "user\ttotal"

      @users.sort_by { |(user, count)| count }.reverse.each do |(user, count)|
        out.puts "#{user}\t#{count}"
      end
    end
  end

  def chart_config
    {
      type: "table",
      name: "Top Users (Last Week)",
      group: "Top Users",
      group_sort: 1,
      options: {
        showRowNumber: true
      },
      columns: [
        { type: 'string', label: 'User' },
        { type: 'number', label: 'PRs' }
      ],
      rows: @users.sort_by { |(user, count)| count }.reverse.map { |(user, count)| [user, count] }.take(20)
    }
  end
end

Report.add(TopUsersLastWeek)
