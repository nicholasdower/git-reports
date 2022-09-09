require_relative 'report'

class PrsPerMonth < Report
  def initialize(config)
    super
    @prs_per_month = {}
  end

  def on_day(day, prs, commits)
    month = (day - day.mday + 1).strftime('%Y-%m-%d')
    @prs_per_month[month] ||= 0
    @prs_per_month[month] += prs.count { |pr| !bot_or_auto?(pr) }
  end

  def on_done
    open("reports/#{@config[:name]}/prs_per_month.tsv", 'w') do |out|
      out.puts "month\ttotal"

      @prs_per_month.each do |month, count|
        out.puts "#{month}\t#{count}"
      end
    end
  end

  def chart_config
    {
      name: 'Pull Requests Per Month',
      options: {
        hAxis: { title: 'Month' },
        vAxis: { title: 'Pull Requests' }
      },
      columns: [
        { type: 'date', label: 'Month' },
        { type: 'number', label: 'PRs' }
      ],
      rows: @prs_per_month.map { |month, prs| [month, prs] }
    }
  end
end

Report.add(PrsPerMonth)
