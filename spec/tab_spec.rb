require 'spec_helper'

def get_tabfile_name(name, type=nil)
  case type
  when 'bpm' then "spec/helper_files/bpm/#{name}"
  when 'time' then "spec/helper_files/time/#{name}"
  when 'tuning' then "spec/helper_files/tuning/#{name}"
  else "spec/helper_files/#{name}"
  end
end

describe Tabbycat::Tab do
  let(:tabfile_name) { 'jsb0846a.txt' }
  let(:tabfile_type) { nil }
  let(:tabfile) { File.read(get_tabfile_name(tabfile_name, tabfile_type)) }

  let(:raw_tab) {
    {
      composerName: "Johann Sebastian Bach",
      name: "BWV 846 - Well Tempered Clavier Book I - Prelude No 1 in C",
      tabFile: "jsb0846a.txt",
      midis: ["jsb0846a.mid"],
      difficulty: "easy",
      misc: "",
      bpm: "?",
      time: "?",
      tuning: "?"
    }
  }

  let(:tab) { Tabbycat::Tab.new(raw_tab) }

  before do
    allow(tab).to receive(:tabfile) { tabfile }
  end

  describe '#incomplete_fields' do
    it 'returns fields that have not been filled' do
      expect(tab.incomplete_fields).to eq({:bpm=>"?", :time=>"?", :tuning=>"?"})
    end
  end

  describe '#guess_bpm' do
    let(:tabfile_type) { 'bpm' }

    context 'When a direct bpm is present' do
      let(:tabfile_name) { 'bpm_specified.txt' }

      it 'finds the numerical bpm' do
        expect(tab.guess_bpm).to eq('110')
      end
    end

    context 'When a q signifier is present' do
      let(:tabfile_name) { 'quarter_note_specified.txt' }

      it 'finds the beats per quarter note' do
        expect(tab.guess_bpm).to eq('130')
      end
    end

    context 'When a speed keyword is present' do
      let(:tabfile_name) { 'speed_keyword.txt' }

      it 'finds Allegro' do
        expect(tab.guess_bpm).to eq('168')
      end
    end

    context 'When no speed is found' do
      let(:tabfile_name) { 'no_speed.txt' }

      it 'defaults to ?' do
        expect(tab.guess_bpm).to eq('?')
      end
    end
  end

  describe '#guess_tuning' do
    let(:tabfile_type) { 'tuning' }

    context 'When the tuning is present on a single line' do
      let(:tabfile_name) { 'open_g_tuning.txt' }

      it 'finds the space delimited tuning' do
        expect(tab.guess_tuning).to eq('D G D G B E')
      end
    end

    context 'When the tuning is present as a line prefix' do
      let(:tabfile_name) { 'open_g_tuning.txt' }

      it 'extracts it from the start of the tab lines' do
        expect(tab.guess_tuning).to eq('D G D G B E')
      end
    end

    context 'When Standard Tuning is present' do
      let(:tabfile_name) { 'standard_tuning.txt' }

      it 'assumes E A D G B E' do
        expect(tab.guess_tuning).to eq('E A D G B E')
      end
    end

    context 'When Dropped D Tuning is present' do
      let(:tabfile_name) { 'drop_d_tuning.txt' }

      it 'assumes D A D G B E' do
        expect(tab.guess_tuning).to eq('D A D G B E')
      end
    end

    context 'When there is no tuning' do
      let(:tabfile_name) { 'empty_tuning.txt' }

      it 'assumes E A D G B E' do
        expect(tab.guess_tuning).to eq('E A D G B E')
      end
    end
  end

  describe '#guess_time_signature' do
    let(:tabfile_type) { 'time' }

    context 'When the time signature is openly present' do
      let(:tabfile_name) { 'time_specified.txt' }

      it 'finds it' do
        expect(tab.guess_time_signature).to eq('6/8')
      end
    end
  end
end
