# frozen_string_literal: true

require 'selenium-webdriver'
require 'yaml'
require 'csv'
require 'uri'
require 'logger'

class ScrapingCodeal
  def initialize
    @keywords = open(File.expand_path('./src/config/search_keyword.yml'), 'r') { |f| YAML.safe_load f }
    @driver = Selenium::WebDriver.for :chrome

    @search_volume_csv_path = File.expand_path('./output/search_vloume.csv')
    @project_csv_path = File.expand_path('./output/project.csv')

    File.delete(@search_volume_csv_path) if File.exist?(@search_volume_csv_path)
    File.delete(@project_csv_path) if File.exist?(@project_csv_path)

    @log = Logger.new(STDOUT)
  end

  def search_keyword_volume(keyword)
    keyword_volume_xpath = "//*[@id='app']/div/div/div/div[2]/div[1]/span[2]"

    begin
      search_result = @driver.find_element(:xpath, keyword_volume_xpath)
      @num_of_projects_displayed_per_page = search_result.text.split(' ')[5].to_i
      keyword_volume = search_result.text.split(' ')[1]

      CSV.open(@search_volume_csv_path, 'a') do |f|
        f << [keyword, keyword_volume]
      end
    rescue => e
      @log.error(e)
    end
  end

  def search_project_job_info
    @job = ''
    begin
      job_info_xpath = "//*[@id='app']/div/div[1]/section/div[1]/div[2]/h1"
      @job = @driver.find_element(:xpath, job_info_xpath).text
    rescue => e
      @log.error(e)
    end
  end

  def search_arrival
    @arrival = ''
    begin
      arrival_xpath = "//*[@id='app']/div/div[1]/section/div[3]/div[1]/div[1]/p"
      @arrival = @driver.find_element(:xpath, arrival_xpath).text
    rescue => e
      @log.error(e)
    end
  end

  def search_salary
    @salary = ''
    begin
      salary_xpath = "//*[@id='app']/div/div[1]/section/div[3]/div[1]/div[2]/div/div/div[1]/div"
      @salary = @driver.find_element(:xpath, salary_xpath).text
    rescue => e
      @log.error(e)
    end
  end

  def search_tag
    @tag = []
    i = 1
    loop do
      begin
        tag_xpath = "//*[@id='app']/div/div[1]/section/div[3]/div[2]/div[#{i}]/button"
        @tag << @driver.find_element(:xpath, tag_xpath).text
      rescue => e
        @log.error(e)
        break
      end
      i += 1
    end
  end

  def search_projects
    @keywords['keyword'].each do |word|
      uri = URI("https://www.codeal.work/jobs?is_application_allowed=true&keyword=#{word}")
      @driver.get(uri)
      keyword_search_top_page_url = @driver.current_url
      current_url = keyword_search_top_page_url
      sleep 2

      search_keyword_volume(word)

      # create search_volume csv.
      p = 1
      loop do
        (2..@num_of_projects_displayed_per_page + 1).each do |i|
          exec_times = i
          # go to project info
          begin
            ancher_xpath = "//*[@id='app']/div/div/div/div[2]/div[#{i}]/section/div[2]/div/a/img"
            @driver.find_element(:xpath, ancher_xpath).click
            sleep 2
          rescue => e
            @log.error(e)
          end

          # 求人詳細
          search_project_job_info

          # office出社頻度
          search_arrival

          # 報酬
          search_salary

          # タグ
          search_tag

          project_url = @driver.current_url

          CSV.open(File.expand_path('./output/project.csv'), 'a') do |f|
            f << [@job, @arrival, @salary, @tag, project_url]
          end

          if exec_times == @num_of_projects_displayed_per_page + 1
            break
          end

          @driver.get(current_url)
        end

        begin
          @driver.get("https://www.codeal.work/jobs?is_application_allowed=true&keyword=ruby&p=#{p + 1}")
          keyword_search_next_page_url = @driver.current_url
          current_url = keyword_search_next_page_url
          sleep 2
        rescue => e
          @log.error(e)
          break
        end
        p += 1
      end
    end
  end

  def finish_scraping
    @driver.quit
  end
end

if __FILE__ == $PROGRAM_NAME
  scraping = Scraping.new
  scraping.search_projects
  scraping.finish_scraping
end
