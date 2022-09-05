require_relative '../report'

class Example < Report
  def generate(config, prs_per_day)
  end
end

Report.add(Example)
