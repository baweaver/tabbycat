module Tabbycat
  class Tab < OpenStruct
    def initialize(tab_hash)
      @tab_hash = tab_hash
      super(tab_hash)
    end

    def incomplete_fields
      @tab_hash.select { |_, v| v == '?' }
    end

    def guess_bpm
      easy_way = tabfile[/\d{1,3} ?bpm/]
      return easy_way.delete('bpm').strip if easy_way

      quarter_notes = tabfile[/[qQ]\.? ?= ?\d+/]
      return quarter_notes.split('=').last.strip if quarter_notes

      '?'
    end

    def guess_tuning
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

    def guess_time_signature
      time_after = tabfile[/(<?time>\d{1,2}\/\d{1,2}).*?([Tt]ime)/]
      return time_after[:time] if time_after

      time_before = tabfile[/([Tt]ime).*?(<?time>\d{1,2}\/\d{1,2})/]
      return time_before[:time] if time_before

      maybe_not_date = tabfile[/\d{1,2}\/\d{1,2}/]

      if maybe_not_date && [2,4,8,16].include?(maybe_not_date.split('/').last.to_i)
        maybe_not_date
      else
        '?'
      end
    end

    def open_on_classtab
      Launchy.open(tabfile_link)
    end

    def open_on_youtube
      Launchy.open(youtube_link)
    end

    private

    def tabfile_link
      "https://baweaver.github.io/classtab/tabs/#{tabFile}"
    end

    def tabfile
      @tabfile ||= Typhoeus.get(tabfile_link).body
    end

    def youtube_link
      if videos
        videos.first['videoLink']
      else
        video_in_tab = tabfile[/https?:\/\/www.youtube.com\/watch?v=[A-Za-z0-9]+/]

        if video_in_tab
          videos << {'videoLink' => video_in_tab}
          video_in_tab
        else
          query = name.gsub(/ /, '+') + ' guitar'
          "https://www.youtube.com/results?search_query=#{query}&page=&utm_source=opensearch"
        end
      end
    end
  end
end
