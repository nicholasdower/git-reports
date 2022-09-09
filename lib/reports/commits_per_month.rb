require_relative 'report'

class CommitsPerMonth < Report
  def initialize(config)
    super
    @commits_per_month = {}
  end

  def on_day(day, prs, commits)
    month = (day - day.mday + 1).strftime('%Y-%m-%d')
    @commits_per_month[month] ||= 0
    @commits_per_month[month] += commits.count { |commit| !bot_or_auto?(commit) && !merge_commit?(commit) }
  end

  def on_done
    open("reports/#{@config[:name]}/commits_per_month.tsv", 'w') do |out|
      out.puts "month\ttotal"

      @commits_per_month.each do |month, count|
        out.puts "#{month}\t#{count}"
      end
    end
  end

  def chart_config
    {
      type: "line",
      name: 'Commits Per Month',
      group: 'Commits',
      group_sort: 3,
      options: {
        hAxis: { title: 'Month' },
        vAxis: { title: 'Commits' }
      },
      columns: [
        { type: 'date', label: 'Month' },
        { type: 'number', label: 'Commits' }
      ],
      rows: @commits_per_month.map { |month, prs| [month, prs] }
    }
  end

  private

  def merge_commit?(commit)
    commit['parents'].length > 1
  end
end

Report.add(CommitsPerMonth)
