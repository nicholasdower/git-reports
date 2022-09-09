require_relative 'report'

class PrsPerWeek < Report
  def initialize(config)
    super
    @prs_per_week = {}
  end

  def on_day(day, prs, commits)
    week = (day - day.wday).strftime('%Y-%m-%d')
    @prs_per_week[week] ||= 0
    @prs_per_week[week] += prs.count { |pr| !bot_or_auto?(pr) }
  end

  def on_done
    open("reports/#{@config[:name]}/prs_per_week.tsv", 'w') do |out|
      out.puts "week\ttotal"

      @prs_per_week.each do |week, count|
        out.puts "#{week}\t#{count}"
      end
    end
  end

  def chart_config
    {
      type: "line",
      name: 'Pull Requests Per Week',
      group: 'Pull Requests',
      group_sort: 2,
      options: {
        hAxis: { title: 'Week' },
        vAxis: { title: 'Pull Requests' }
      },
      columns: [
        { type: 'date', label: 'Week' },
        { type: 'number', label: 'PRs' }
      ],
      rows: @prs_per_week.map { |week, prs| [week, prs] }
    }
  end
end

Report.add(PrsPerWeek)
