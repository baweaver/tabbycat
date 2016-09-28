module Tabbycat
  class Dataset
    include Enumerable

    def initialize(tab_json_file_name = Tabbycat::TAB_JSON_FILE_NAME)
      @tab_json_file_name = tab_json_file_name
    end

    def each(&block)
      tabs.each(&block)
    end

    def composers
      tab_json['composers']
    end

    def tabs
      @tabs ||= tab_json['tabs'].map { |t| OpenStruct.new(t) }
    end

    def save
      tab_json['tabs'] = tabs.map(&:to_h)
      File.open(TAB_JSON_FILE_NAME, 'w') { |f| f.puts JSON.pretty_generate(tab_json) }
    end

    private

    def get_tabs
      JSON.parse File.read(@tab_json_file_name)
    end

    def tab_json(cached = true)
      if cached
        @tab_json ||= get_tabs
      else
        get_tabs
      end
    end
  end
end
