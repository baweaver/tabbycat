module Tabbycat
  class Grokker
    attr_reader :dataset

    def initialize(file_name: Tabbycat::TAB_JSON_FILE_NAME, mode: 'remote', base_link: nil)
      @dataset = Tabbycat::Dataset.new(
        tab_json_file_name: file_name, mode: mode, base_link: base_link
      )
    end

    def cli
      @cli ||= HighLine.new
    end

    def test_accuracy(type)
      guess_type = case type
      when 'bpm'            then 'guess_bpm'
      when 'time_signature' then 'guess_time_signature'
      when 'tuning'         then 'guess_tuning'
      else raise "Don't know how to guess for #{type}"
      end

      puts "Testing accuracy for grokking #{type}", '-' * 80, ''
      bad_guesses = dataset.select { |tab|
        begin
          guess = tab.public_send(guess_type)
        rescue => e
          puts e
          guess = '?'
        end

        printf "  %-10s -> %80s\n", guess, "#{tab.name} (#{type})"
        guess == '?'
      }

      total_tabs = dataset.to_a.size

      puts '', '-' * 80, ''
      puts "Accuracy across #{total_tabs} tabs was: #{(bad_guesses.size / total_tabs.to_f) * 100}%"

      bad_guesses
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
