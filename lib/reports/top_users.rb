require_relative 'report'

class TopUsers < Report
  def initialize(config)
    super
    @users = {}
  end

  def on_day(day, prs, commits)
    prs.each do |pr|
      unless bot_or_auto?(pr)
        login = pr['user']['login']
        @users[login] ||= 0
        @users[login] += 1
      end
    end
  end

  def on_done
    open("reports/#{@config[:name]}/top_users.tsv", 'w') do |out|
      out.puts "user\ttotal"

      @users.sort_by { |(user, count)| count }.reverse.each do |(user, count)|
        out.puts "#{user}\t#{count}"
      end
    end
  end
end

Report.add(TopUsers)
