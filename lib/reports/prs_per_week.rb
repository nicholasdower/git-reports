require_relative 'report'

class PrsPerWeek < Report
  def generate(config, prs_per_day)
    open("reports/#{config[:name]}/prs_per_week.tsv", 'w') do |out|
      out.puts "week\ttotal"

      prs_per_week = {}

      prs_per_day.each do |day, prs|
        week = (day - day.wday).strftime('%Y-%m-%d')
        prs_per_week[week] ||= []
        prs_per_week[week].concat(prs)
      end

      prs_per_week.each do |week, prs|
        count = prs.count { |pr| !bot_or_auto?(pr) }
        out.puts "#{week}\t#{count}"
      end
    end
  end
end

Report.add(PrsPerWeek)
