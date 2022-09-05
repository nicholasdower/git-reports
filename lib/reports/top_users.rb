require_relative 'report'

class TopUsers < Report
  def generate(config, prs_per_day)
    open("reports/#{config[:name]}/top_users.tsv", 'w') do |out|
      out.puts "user\ttotal"

      users = {}
      prs_per_day.each do |day, prs|
        prs.each do |pr|
          unless bot_or_auto?(pr)
            login = pr['user']['login']
            users[login] ||= []
            users[login] << pr
          end
        end
      end

      users.sort_by { |(user, prs)| prs.size }.reverse.each do |(user, prs)|
        out.puts "#{user}\t#{prs.size}"
      end
    end
  end
end

Report.add(TopUsers)
