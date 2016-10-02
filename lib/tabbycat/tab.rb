module Tabbycat
  class Tab < OpenStruct
    attr_reader :base_link

    BASE_LINK = "https://baweaver.github.io/classtab/tabs"

    SPEED_KEYWORDS = {
      'larghissimo'      => '24',
      'grave'            => '45',
      'largo'            => '60',
      'lento'            => '60',
      'larghetto'        => '66',
      'adagio'           => '76',
      'adagietto'        => '76',
      'andante'          => '108',
      'andantino'        => '108',
      'marcia moderato'  => '85',
      'andante moderato' => '112',
      'moderato'         => '120',
      'allegretto'       => '120',
      'allegro moderato' => '120',
      'allegro'          => '168',
      'vivace'           => '176',
      'vivacissimo'      => '176',
      'allegrissimo'     => '176',
      'allegro vivace'   => '176',
      'presto'           => '200',
      'prestissimo'      => '200'
    }

    SPEED_WORD_REGEXP = Regexp.union SPEED_KEYWORDS.keys.map { |k|
      /#{Regexp.escape k}/i
    }

    def initialize(tab_hash, base_link = BASE_LINK)
      @tab_hash = tab_hash
      super(tab_hash)
    end

    def incomplete_fields
      @tab_hash.select { |_, v| v == '?' }
    end

    def guess_bpm
      # They kindly put it in the file in a simple format. Good on you!
      easy_way = tabfile[/\d{1,3} ?bpm/]
      return easy_way.delete('bpm').strip if easy_way

      # Ok ok, so maybe they used the q= format to signify quarter note speed
      quarter_notes = tabfile[/[qQ]\.? ?= ?\d+/]
      return quarter_notes.split('=').last.strip if quarter_notes

      # How about speed keywords like Allegro?
      speed_words = tabfile[SPEED_WORD_REGEXP]
      return SPEED_KEYWORDS[speed_words.downcase] if speed_words

      # Well you got me.
      '?'
    end

    def guess_tuning
      # Let's see if they put standard tuning in there
      standard_tuning = tabfile[/standard tuning/i]
      return 'E A D G B E' if standard_tuning

      # Maybe a 6=D?
      drop_d_6 = tabfile[/6 ?= ?d/i]
      return 'D A D G B E' if drop_d_6

      # Or just wrote out drop d somewhere
      drop_d_written = tabfile[/drop(ped)? d/i]
      return 'D A D G B E' if drop_d_written

      # Some prefer to put the tuning as is on there.
      standalone_tuning = tabfile[/[A-Ge] ?([A-G] ?){4}[A-G]/i]
      return standalone_tuning.delete(' ').chars.map(&:upcase).join(' ') if standalone_tuning

      # Or you have to go through the lines for it. Good luck
      lined_tuning = tabfile.scan(/^ ?([A-Ga-g])[|:-].*{40,}/i)
      return lined_tuning.flatten.first(6).reverse.map(&:upcase).join(' ') unless lined_tuning.empty?

      # We'll just guess they wanted standard tuning.
      'E A D G B E'
    end

    def guess_time_signature
      # Some times they'll specify 'time' after the signature.
      time_after = tabfile[/(<?time>\d{1,2}\/\d{1,2}).*?([Tt]ime)/]
      return time_after[:time] if time_after

      # or maybe before?
      time_before = tabfile[/([Tt]ime).*?(<?time>\d{1,2}\/\d{1,2})/]
      return time_before[:time] if time_before

      # Let's just hope it's not a date again
      maybe_not_date = tabfile[/\d{1,2}\/\d{1,2}/]

      # Most all key signatures I've found have an even denominator. I'd rather have
      # it tell me it's not sure than pluck a date again.
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
      "#{base_link}/#{tabFile}"
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
