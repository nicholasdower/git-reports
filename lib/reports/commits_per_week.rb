require_relative 'report'

class CommitsPerWeek < Report
  def initialize(config)
    super
    @commits_per_week = {}
  end

  def on_day(day, prs, commits)
    week = (day - day.wday).strftime('%Y-%m-%d')
    @commits_per_week[week] ||= 0
    @commits_per_week[week] += commits.count { |commit| !bot_or_auto?(commit) && !merge_commit?(commit) }
  end

  def on_done
    open("reports/#{@config[:name]}/commits_per_week.tsv", 'w') do |out|
      out.puts "week\ttotal"

      @commits_per_week.each do |week, count|
        out.puts "#{week}\t#{count}"
      end
    end
  end

  def chart_config
    {
      type: "line",
      name: 'Commits Per Week',
      group: 'Commits',
      group_sort: 2,
      options: {
        hAxis: { title: 'Week' },
        vAxis: { title: 'Commits' }
      },
      columns: [
        { type: 'date', label: 'Week' },
        { type: 'number', label: 'Commits' }
      ],
      rows: @commits_per_week.map { |week, prs| [week, prs] }
    }
  end

  private

  def merge_commit?(commit)
    commit['parents'].length > 1
  end
end

Report.add(CommitsPerWeek)
