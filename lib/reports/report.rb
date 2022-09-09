class Report

  def self.add(clazz)
    @all ||= []
    @all << clazz
  end

  def self.all
    @all
  end

  attr_accessor :config

  def initialize(config)
    @config = config
  end

  def bot?(pr_or_commit)
    if pr_or_commit['user']
      @config[:bots].include?(pr_or_commit['user']['login'])
    elsif pr_or_commit['commit']
      @config[:bots].include?(pr_or_commit['author']&.send(:[], 'login'))
    else
      raise "Not a PR or commit."
    end
  end

  def auto?(pr_or_commit)
    if pr_or_commit['title']
      !!(pr_or_commit['title'] =~ /#{@config[:auto_regex]}/) if @config[:auto_regex]
    elsif pr_or_commit['commit']
      !!(pr_or_commit['commit']['message'] =~ /#{@config[:auto_regex]}/) if @config[:auto_regex]
    else
      raise "Not a PR or commit."
    end
  end

  def bot_or_auto?(pr)
    bot?(pr) || auto?(pr)
  end

  def on_day(day, prs, commits)
  end

  def on_done
  end

  def chart_config
  end
end
