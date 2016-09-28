require "tabbycat/version"
require 'json'
require 'highline'
require 'launchy'
require 'typhoeus'

# No, really, this is going to be dirty until I decide to clean it.
module Tabbycat
  TAB_JSON_FILE_NAME = '../classtab/app/data/tabs_flat.json'
end

require 'tabbycat/dataset'
require 'tabbycat/grokker'
