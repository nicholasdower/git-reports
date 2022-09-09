require_relative '../report'

class Example < Report
  def initialize(config)
    super
  end

  def on_day(day, prs, commits)
  end

  def on_done
  end
end

Report.add(Example)
