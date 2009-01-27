# desc "Explaining what the task does"
# task :gettext_to_i18n do
#   # Task goes here
# end

require File.dirname(__FILE__) + '/../init'

namespace :gettext_to_i18n do
  
  desc 'Creates instance of Base'
  task :create_base do
    @base = GettextToI18n::Base.new
  end

  desc 'Transforms all of your files into the new I18n api format'
  task :transform => [:create_base] do
    @base.prepare_conversion
    @base.dump_yaml!
  end
  
  desc 'Tries to extract all what is possible from po files for languages'
  task :converse_po_to_yml => [:create_base] do
    #TODO add arguments
    @base.converse_po!('phdstudy.po', 'cs_CZ')
  end
  
end
