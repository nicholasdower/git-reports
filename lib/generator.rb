require 'date'
require 'fileutils'
require 'json'
require 'octokit'

Dir.chdir('lib') { Dir.glob('reports/**/*.rb').each { |file| require_relative file } }

class Generator
  DEFAULT_CONFIG = {
    start_day: '2022-01-01',
    github_token: nil,
    end_day: (Date.today - 1).to_s,
    auto_regex: nil,
    rate_limit: 11,
    prs_github_search: nil,
    commits_github_search: nil,
    reports_dir: 'reports',
    user_breakdown: false,
    bots: [],
    teams: {}
  }

  def initialize(log: STDERR)
    @log = log
  end

  def run(args = ARGV)
    raise "Unexpected args: #{ARGV}" if ARGV.size > 1
    config_file = ARGV[0]

    @config = parse_config(file: config_file)
    @client = Octokit::Client.new(:access_token => @config[:github_token])

    FileUtils.mkdir_p("data/#{@config[:name]}/commits")
    FileUtils.mkdir_p("data/#{@config[:name]}/prs")
    FileUtils.rm_rf("reports/#{@config[:name]}")
    FileUtils.mkdir_p("reports/#{@config[:name]}")

    days = find_days_in_range(@config[:start_day], @config[:end_day])

    fetch_missing_data(days.reverse)

    #downloaded_shas = commits_per_day.flat_map do |day, commits|
    #  commits.map do |commit|
    #    commit['sha']
    #  end
    #end
    #commits_per_day.each do |day, commits|
    #  if day > Date.today - 10
    #    commits.each do |commit|
    #      commit['parents'].map do |parent|
    #        unless downloaded_shas.include?(parent['sha'])
    #          puts parent['html_url']
    #        end
    #      end
    #    end
    #  end
    #end
    #parent_shas = commits_per_day.flat_map do |day, commits|
    #  commits.flat_map do |commit|
    #    commit['parents'].map do |parent|
    #      parent['sha']
    #    end
    #  end
    #end
    #missing_shas = downloaded_shas - parent_shas

    reports = Report.all.map do |report|
      report.new(@config)
    end

    days.each do |day|
      prs = get_prs_from_file(day)
      commits = get_commits_from_file(day)
      reports.each do |report|
        report.on_day(day, prs, commits)
      end
    end

    chart_configs = []
    reports.each do |report|
      report.on_done
      chart_config = report.chart_config
      if chart_config.is_a?(Array)
        chart_configs.concat(chart_config)
      elsif chart_config.is_a?(Hash)
        chart_configs << chart_config if chart_config
      elsif !chart_config.nil?
        raise "Invalid chart config for #{report}"
      end
    end
    chart_configs.sort! { |a, b| [a[:group], a[:group_sort]] <=> [b[:group], b[:group_sort]] }

    File.write("reports/#{@config[:name]}/data.js", "chart_configs = #{JSON.pretty_generate(chart_configs)}")
    FileUtils.cp('github-reports.js', "reports/#{@config[:name]}/")
    FileUtils.cp('github-reports.css', "reports/#{@config[:name]}/")
    FileUtils.cp('github-reports.html', "reports/#{@config[:name]}/")

    #prs_per_day.each do |day, prs|
    #  prs.each do |pr|
    #    if pr['user']['login'] == 'dziemba'
    #      puts pr['title']
    #    end
    #  end
    #end
  end

  private

  def parse_config(file: nil)
    config = DEFAULT_CONFIG.dup

    if file
      @log.puts "Using config file: #{file}"
      config.merge!(JSON.parse(File.read(file), symbolize_names: true))
    else
      @log.puts 'Using default config'
    end

    raise "Missing config name." unless config[:name]

    raise "Missing GitHub token." unless config[:github_token]
    raise "Missing PR GitHub search." unless config[:prs_github_search]
    raise "Missing commit GitHub search." unless config[:commits_github_search]

    user_breakdown = config[:user_breakdown]
    raise "Invalid team config" unless user_breakdown.is_a?(TrueClass) || user_breakdown.is_a?(FalseClass)

    teams = config[:teams]
    raise "Invalid team config." unless teams.is_a?(Hash)

    config[:start_day] = Date.parse(config[:start_day])
    config[:end_day] = Date.parse(config[:end_day])

    if config[:start_day] > config[:end_day]
      raise "Start day (#{config[:start_day]}) is after end day (#{config[:end_day]})."
    end

    if config[:end_day] >= Date.today
      raise "End day (#{config[:end_day]}) must be before today."
    end

    config
  end

  def fetch_missing_data(days)
    commits_days = days.select do |day, i|
      !commits_file_exists?(day)
    end
    prs_days = days.select do |day, i|
      !prs_file_exists?(day)
    end
    days = (commits_days.to_set + prs_days.to_set).to_a

    if days.empty?
      @log.puts "All data already fetched."
      return
    end

    @log.puts "Fetching data for #{days.size} day(s)"

    days.each_with_index do |day, i|
      if prs_days.include?(day)
        @log.puts "Fetching PR data for #{day} (#{i + 1} of #{days.size})"
        File.open("data/#{@config[:name]}/prs/#{day}", 'w') do |file|
          file.write(get_prs_from_api(day).to_json)
        end
        chill unless i == days.size - 1 && commits_days.include?(day)
      end

      if commits_days.include?(day)
        @log.puts "Fetching commit data for #{day} (#{i + 1} of #{days.size})"
        file_name = "data/#{@config[:name]}/commits/#{day}"
        File.open("data/#{@config[:name]}/commits/#{day}", 'w') do |file|
          file.write(get_commits_from_api(day).to_json)
        end
        chill unless i == days.size - 1
      end
    end
  end

  def chill
    delay = @config[:rate_limit]
    @log.puts "Sleeping #{delay}s"
    sleep(delay)
  end

  def prs_file_exists?(day)
    file_name = "data/#{@config[:name]}/prs/#{day}"
    File.exist?(file_name) && File.mtime(file_name).to_date > day
  end

  def commits_file_exists?(day)
    file_name = "data/#{@config[:name]}/commits/#{day}"
    File.exist?(file_name) && File.mtime(file_name).to_date > day
  end

  def get_prs_from_file(day)
    file_name = "data/#{@config[:name]}/prs/#{day}"
    JSON.parse(File.read(file_name))
  end

  def get_commits_from_file(day)
    file_name = "data/#{@config[:name]}/commits/#{day}"
    JSON.parse(File.read(file_name))
  rescue StandardError
    puts day
    raise
  end

  def get_commits_from_api(day)
    get_search_results_from_api do
      @client.search_commits("#{@config[:commits_github_search]} committer-date:#{day}", { sort: 'created', order: 'desc', page: 1, per_page: 100})
    end
  end

  def get_prs_from_api(day)
    get_search_results_from_api do
      @client.search_issues("is:pr #{@config[:prs_github_search]} created:#{day}", { sort: 'created', order: 'desc', page: 1, per_page: 100})
    end
  end

  def get_search_results_from_api
    result = yield
    items = []

    while true
      items.concat(result.items.map(&:to_hash))

      if @client.last_response.rels[:next]
        chill
        result = @client.get(@client.last_response.rels[:next].href)
      else
        break
      end
    end

    items
  end

  def find_days_in_range(start_day, end_day)
    days = [end_day]

    while days[0] > start_day
      days.unshift(days[0] - 1)
    end

    days
  end
end

Generator.new.run
