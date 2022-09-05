class Report

  def self.add(clazz)
    @all ||= []
    @all << clazz
  end

  def self.all
    @all
  end

  attr_accessor :config, :prs_per_day

  def initialize(config, prs_per_day)
    @config = config
    @prs_per_day = prs_per_day
  end

  def bot?(pr)
    @config[:bots].include?(pr['user']['login'])
  end

  def auto?(pr)
    !!(pr['title'] =~ /#{@config[:auto_regex]}/) if @config[:auto_regex]
  end

  def bot_or_auto?(pr)
    bot?(pr) || auto?(pr)
  end

  def generate
  end
end
