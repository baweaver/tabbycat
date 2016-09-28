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

        tabfile = Typhoeus.get(tab_link(tab)).body

        get_youtube(tab, tabfile) if tab.difficulty == 'none'
        get_tabfile(tab)

        tab.tuning     = cli.ask("  Tuning?: ")     { |q| q.default = rip_tuning(tabfile) }
        tab.time       = cli.ask("  Time?: ")       { |q| q.default = rip_time(tabfile) }
        tab.bpm        = cli.ask("  Bpm?: ")        { |q| q.default = rip_bpm(tabfile) }
        tab.difficulty = cli.ask('  Difficulty?: ') { |q| q.default = tab.difficulty }

        dataset.save
      end
    end

    private

    def get_youtube(tab, tabfile)
      Launchy.open(youtube_link(tab, tabfile))
    end

    def get_tabfile(tab)
      Launchy.open tab_link(tab)
    end

    def rip_time(tabfile)
      time_after = tabfile[/(<?time>\d{1,2}\/\d{1,2}).*?([Tt]ime)/]
      return time_after[:time] if time_after

      time_before = tabfile[/([Tt]ime).*?(<?time>\d{1,2}\/\d{1,2})/]
      return time_before[:time] if time_before

      dangit_just_guess_and_hope_its_not_a_date = tabfile[/\d{1,2}\/\d{1,2}/]

      dangit_just_guess_and_hope_its_not_a_date ? dangit_just_guess_and_hope_its_not_a_date.strip : '?'
    end

    def rip_tuning(tabfile)
      standard_tuning = tabfile[/[Ss]tandard tuning/]
      return 'E A D G B E' if standard_tuning

      standalone_tuning = tabfile[/[A-Ge] ?([A-G] ?){4}[A-G]/]
      return standalone_tuning.delete(' ').chars.join(' ') if standalone_tuning

      lined_tuning = tabfile.scan(/^([A-Ga-g])[|:-].*{40,}/)
      return lined_tuning.flatten.first(6).reverse.map(&:upcase).join(' ') unless lined_tuning.empty?

      drop_d_6 = tabfile[/6 ?= ?[dD]/]
      return 'D A D G B E' if drop_d_6

      drop_d_written = tabfile[/[Dd]rop(ped)? [Dd]/]
      return 'D A D G B E' if drop_d_written

      'E A D G B E'
    end

    def rip_bpm(tabfile)
      easy_way = tabfile[/\d{1,3} ?bpm/]
      return easy_way.delete('bpm').strip if easy_way

      quarter_notes = tabfile[/[qQ]=\d+/]
      return quarter_notes.split('=').last.strip if quarter_notes

      '?'
    end

    def youtube_link(tab)
      if tab.videos
        tab.videos.first['videoLink']
      else
        video_in_tab = tabfile[/https?:\/\/www.youtube.com\/watch?v=[A-Za-z0-9]+/]

        if video_in_tab
          tab.videos << {'videoLink' => video_in_tab}
          video_in_tab
        else
          query = tab.name.gsub(/ /, '+') + ' guitar'
          "https://www.youtube.com/results?search_query=#{query}&page=&utm_source=opensearch"
        end
      end
    end

    def tab_link(tab)
      "https://baweaver.github.io/classtab/tabs/#{tab.tabFile}"
    end
  end
end
