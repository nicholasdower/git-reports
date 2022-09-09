require_relative 'report'

class CommitsPerDay < Report
  def initialize(config)
    super
    @commits_per_day = {}
  end

  def on_day(day, prs, commits)
    @commits_per_day[day] = commits.count { |commit| !bot_or_auto?(commit) }
  end

  def on_done
    open("reports/#{@config[:name]}/commits_per_day.tsv", 'w') do |out|
      out.puts "day\ttotal"
      @commits_per_day.each do |day, count|
        out.puts "#{day}\t#{count}"
      end
    end
  end

  def chart_config
    {
      name: 'Commits Per Day',
      options: {
        hAxis: { title: 'Day' },
        vAxis: { title: 'Commits' }
      },
      columns: [
        { type: 'date', label: 'Day' },
        { type: 'number', label: 'Commits' }
      ],
      rows: @commits_per_day.map { |day, prs| [day, prs] }
    }
  end
end

Report.add(CommitsPerDay)
