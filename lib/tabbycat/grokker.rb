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
      dataset.each do |tab|
        puts JSON.pretty_generate(tab.to_h)

        if tab.incomplete_fields.size < 2
          puts "  Already completed #{tab.name}!"
          next
        end

        tab.open_on_youtube if tab.difficulty == 'none'
        tab.open_on_classtab

        tab.tuning     = cli.ask("  Tuning?: ")     { |q| q.default = tab.guess_tuning }
        tab.time       = cli.ask("  Time?: ")       { |q| q.default = tab.guess_time_signature }
        tab.bpm        = cli.ask("  Bpm?: ")        { |q| q.default = tab.guess_bpm }
        tab.difficulty = cli.ask('  Difficulty?: ') { |q| q.default = tab.difficulty }

        dataset.save
      end
    end
  end
end
