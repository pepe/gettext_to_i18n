module GettextToI18n
  
  class Base
    include GetText
    attr_reader :translations
    LOCALE_DIR = File.join(RAILS_ROOT, '/config/locales/')
    TEMPLATE_LOCALE_FILE = 'template.yml'
    DEFAULT_LANGUAGE = 'some-LAN'

    def initialize
      @translations = {}
    end
    
    # transforms and dumps the translation strings into config/locales/template.yml
    def dump_yaml!
      FileUtils.mkdir_p LOCALE_DIR
      File.open(template_file,'w+'){ |f| YAML::dump(@translations, f) } 
    end

    # transform all files
    def prepare_conversion
      transform_files!(:controller)
      transform_files!(:model)
      transform_files!(:view)
      transform_files!(:helper)
      transform_files!(:lib)
    end

    # converses po files to yml
    def converse_po!(file, lang)
      po_file = File.join(RAILS_ROOT, 'po', lang, file)
      lang_file = lang.split('-')[0] + '.rb'
      i18n_file = File.open(File.join(LOCALE_DIR, lang_file),'w+')

      i18n_text = File.read(template_file)

      po_pairs = parse_po(po_file)
      
      po_pairs.each_pair do|msgid, msgstr|
        next if msgid == ''
        puts msgid
        msgregexp = Regexp.new(": " + msgid + "$")
        puts msgregexp 
        i18n_text.gsub!(msgregexp, ': ' + msgstr)
      end
     
      i18n_file.write i18n_text
      i18n_file.close
      

    end

    # returns template file
    def template_file
      File.join(LOCALE_DIR, TEMPLATE_LOCALE_FILE)
    end

    # parse po files and returns hash with msgid => msgstr
    def parse_po(file)
      parser = PoParser.new
      data = MOFile.new
      parser.parse(File.read(file), data)
      return data
    end

    
    private 
    
    # Walks all files and converts them all to the new format
    def transform_files!(type)  
      files =  Files.send(type.to_s + "_files")
      files.each do |file|
        parsed = ""
        namespace = [DEFAULT_LANGUAGE, 'txt', type] + Base.get_namespace(file, type)
        puts "Converting: " + file + " into namespace: "
        puts namespace.map {|x| "[\"#{x}\"]"}.join("")
        
        namespace = Namespace.new(namespace)
        contents = File.read(file)
        parsed << GettextI18nConvertor.string_to_i18n(contents, namespace)

        File.open(file, 'w') { |file| file.write(parsed)}
        
        namespace.merge(@translations)
      end
    end
    
    # prepares all ymls for namespaces
    def prepare_ymls
      yml = YAML::load(File.open(TEMPLATE_LOCALE_FILE))
      #TODO move to its own class?
      return {
        :models_po => yml['some-LAN']['txt']['model'],
        :controllers_po => yml['some-LAN']['txt']['controller'],
        :views_po => yml['some-LAN']['txt']['view'],
        :helpers_po => yml['some-LAN']['txt']['helper']
      }
    end
    
    # returns a name for a file
    # example: 
    # Base.get_name('/controllers/apidoc_controller.rb', 'controller') => 'apidoc'
    def self.get_namespace(file, type)
     case type

       when :controller
         if result = /application\.rb/.match(file)
           return ['application']
         else
           result = /([a-zA-Z]+)_controller.rb/.match(file)
           return [result[1]]
         end
         return ""
       when :helper
         result = /([a-zA-Z]+)_helper.rb/.match(file)
         return [result[1]]
       when :model
          result = /([a-zA-Z]+).rb/.match(file)
          return [result[1]]
       when :view
         result = /views\/([\_a-zA-Z]+)\/([\_a-zA-Z]+).*\.([a-zA-Z]+)/.match(file)
         if result[3] != "erb"
           return [result[1], result[2], result[3]]
         else
           return [result[1], result[2]] 
         end
        when :lib
          result = /([a-zA-Z]+).rb/.match(file)
          return [result[1]]
     end
    end
    
  end
end
