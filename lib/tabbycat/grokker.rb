module Tabbycat
  class Grokker
    attr_reader :dataset

    def initialize(file_name = Tabbycat::TAB_JSON_FILE_NAME)
      @dataset = Tabbycat::Dataset.new(file_name)
    end

    def cli
      @cli ||= HighLine.new
    end

    def run
      puts "Now I'm just going to assume you want to fill out data for now.",
           '',
           "Shall we get started then?",
           ''

      dataset.each do |tab|
        puts JSON.pretty_generate(tab.to_h)

        if [
          tab.tuning,
          tab.time,
          tab.bpm,
          tab.difficulty
        ].none? { |v| v.nil? || v.empty? }
          puts "  Already completed #{tab.name}!"
          next
        end

        Launchy.open youtube_link(tab) if tab.difficulty == 'none'
        Launchy.open tab_link(tab)

        tabfile = Typhoeus.get(tab_link(tab)).body

        tab.tuning     = cli.ask("  Tuning?: ")     { |q| q.default = rip_tuning(tabfile) }
        tab.time       = cli.ask("  Time?: ")       { |q| q.default = tabfile[/\d{1,2}\/\d{1,2}/] || '4/4' }
        tab.bpm        = cli.ask("  Bpm?: ")        { |q| q.default = tabfile[/\d{1,3} bpm/] || '100' }
        tab.difficulty = cli.ask('  Difficulty?: ') { |q| q.default = tab.difficulty }

        save_it = cli.ask("    Save Progress? (y/n/b)").chomp.strip
        dataset.save if save_it == 'y'
        break if save_it == 'b'
      end

      dataset.save
    end

    private

    def rip_tuning(tabfile)
      standalone_tuning = tabfile[/([A-G] ){5}[A-G]/]
      return standalone_tuning if standalone_tuning

      lined_tuning = data.scan(/([A-G])\|.*$\n/)
      return lined_tuning.first(6).reverse.join(' ') unless lined_tuning.empty?

      'E A D G B E'
    end

    def youtube_link(tab)
      query = tab.name.gsub(/ /, '+') + ' guitar'

      "https://www.youtube.com/results?search_query=#{query}&page=&utm_source=opensearch"
    end

    def tab_link(tab)
      "https://baweaver.github.io/classtab/tabs/#{tab.tabFile}"
    end
  end
end
