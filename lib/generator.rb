require 'date'
require 'fileutils'
require 'json'
require 'octokit'

Dir.chdir('lib') { Dir.glob('reports/**/*.rb').each { |file| require_relative file } }

class Generator
  MIN_DELAY = 10

  DEFAULT_CONFIG = {
    start_day: '2022-01-01',
    github_token: nil,
    end_day: (Date.today - 1).to_s,
    auto_regex: nil,
    github_search: nil,
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

    FileUtils.mkdir_p("data/#{@config[:name]}")
    FileUtils.rm_rf("reports/#{@config[:name]}")
    FileUtils.mkdir_p("reports/#{@config[:name]}")

    days = find_days_in_range(@config[:start_day], @config[:end_day])

    fetch_missing_pr_data(days)
    prs_per_day = load_pr_data(days)

    Report.all.each do |report|
      report.new(@config, prs_per_day).generate(@config, prs_per_day)
    end
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
    raise "Missing GitHub search." unless config[:github_search]

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

  def fetch_missing_pr_data(days)
    days = days.select do |day, i|
      !pr_file_exists?(day)
    end

    if days.empty?
      @log.puts "All data already fetched."
      return
    end

    @log.puts "Fetching PR counts for #{days.size} day(s)"

    days.each_with_index do |day, i|
      file_name = "data/#{@config[:name]}/#{day}"
      @log.puts "Fetching #{day} (#{i + 1} of #{days.size})"
      prs = get_prs_from_api(day)
      @log.puts "Fetched: #{day}, #{prs.size}"
      File.open(file_name, 'w') do |file|
        file.write(prs.to_json)
      end
      chill unless i == days.size - 1
    end
  end

  def load_pr_data(days)
    days.map do |day|
      [day, get_prs_from_file(day)]
    end.to_h
  end

  def chill
    rate_limit = @client.rate_limit
    delay = (rate_limit.resets_in.to_f / rate_limit.remaining.to_f).ceil
    delay = [MIN_DELAY, delay].max
    @log.puts "Sleeping #{delay}s\t(Rate Limit: #{rate_limit.limit}\tRemaining: #{rate_limit.remaining}\tReset: #{rate_limit.resets_in}s)"
    sleep(delay)
  end

  def pr_file_exists?(day)
    file_name = "data/#{@config[:name]}/#{day}"
    File.exist?(file_name) && File.mtime(file_name).to_date > day
  end

  def get_prs_from_file(day)
    file_name = "data/#{@config[:name]}/#{day}"
    JSON.parse(File.read(file_name))
  end

  def get_prs_from_api(day)
    result = @client.search_issues("is:pr #{@config[:github_search]} created:#{day}", { sort: 'created', order: 'desc', page: 1, per_page: 100})
    prs = []

    while true
      prs.concat(result.items.map(&:to_hash))

      if @client.last_response.rels[:next]
        chill
        result = @client.get(@client.last_response.rels[:next].href)
      else
        break
      end
    end

    prs
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
