module GettextToI18n
  
  class Base
    attr_reader :translations
    LOCALE_DIR = RAILS_ROOT + '/config/locales/'
    TEMPLATE_LOCALE_FILE = LOCALE_DIR + 'template.yml'
    DEFAULT_LANGUAGE = 'some-LAN'

    def initialize
      @translations = {}
    end
    
    # Walks all files and converts them all to the new format
    def transform_files!(files, type)  
      files.each do |file|
        parsed = ""
        namespace = [DEFAULT_LANGUAGE, 'txt', type] + Base.get_namespace(file, type)
        puts "Converting: " + file + " into namespace: "
        puts namespace.map {|x| "[\"#{x}\"]"}.join("")
        
        n = Namespace.new(namespace)
        
        contents = File.read(file)
        parsed << GettextI18nConvertor.string_to_i18n(contents, n)
  
        #puts parsed
        # write the file
        
        File.open(file, 'w') { |file| file.write(parsed)}
        
        
        
        n.merge(@translations)
      end
    end
    
    # transforms and dumps the translation strings into config/locales/template.yml
    def dump_yaml!
      transform_files!(Files.controller_files, :controller)
      transform_files!(Files.model_files, :model)
      transform_files!(Files.view_files, :view)
      transform_files!(Files.helper_files, :helper)
      transform_files!(Files.lib_files, :lib)

      FileUtils.mkdir_p LOCALE_DIR
      File.open(TEMPLATE_LOCALE_FILE,'w+') { |f| YAML::dump(@translations, f) } 
    end

    # converses po files to yml
    def converses_po!(file)
      po_pairs = parse_po(file)
      
      prepare_ymls


    end

    # parse po files and returns hash with msgid => msgstr
    def parse_po(file)
      parser = PoParser.new
      data = MOFile.new
      parser.parse(File.read(file), data)
      return data
    end

    
    private 
    
    # prepares all ymls for namespaces
    def prepare_ymls
      yml = YAML::load(File.open(TEMPLATE_LOCALE_FILE))
      #TODO move to constants maybe its own class?
      return @namespace_ymls = {
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
