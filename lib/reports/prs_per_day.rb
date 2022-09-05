require_relative 'report'

class PrsPerDay < Report
  def generate(config, prs_per_day)
    open("reports/#{@config[:name]}/prs_per_day.tsv", 'w') do |out|
      out.puts "day\ttotal"
      prs_per_day.each do |day, prs|
        count = prs.count { |pr| !bot_or_auto?(pr) }
        out.puts "#{day}\t#{count}"
      end
    end
  end
end

Report.add(PrsPerDay)
