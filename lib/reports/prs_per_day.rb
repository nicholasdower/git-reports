require_relative 'report'

class PrsPerDay < Report
  def initialize(config)
    super
    @prs_per_day = {}
  end

  def on_day(day, prs, commits)
    @prs_per_day[day] = prs.count { |pr| !bot_or_auto?(pr) }
  end

  def on_done
    open("reports/#{@config[:name]}/prs_per_day.tsv", 'w') do |out|
      out.puts "day\ttotal"
      @prs_per_day.each do |day, count|
        out.puts "#{day}\t#{count}"
      end
    end
  end

  def chart_config
    {
      type: "line",
      name: 'Pull Requests Per Day',
      group: 'Pull Requests',
      group_sort: 1,
      options: {
        hAxis: { title: 'Day' },
        vAxis: { title: 'Pull Requests' }
      },
      columns: [
        { type: 'date', label: 'Day' },
        { type: 'number', label: 'PRs' }
      ],
      rows: @prs_per_day.map { |day, prs| [day, prs] }
    }
  end
end

Report.add(PrsPerDay)
