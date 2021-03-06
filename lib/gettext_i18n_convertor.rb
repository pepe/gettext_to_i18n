module GettextToI18n
  class GettextI18nConvertor
    attr_accessor :text
    
    QUOTES_REGEX = /\_\((['"])([^\1]*)\1\)/
    VARIABLES_REGEX = /\%[\s]+\{(.*)\}/
    VARIABLE_REGEX = /\s*:(\w+)\s*=>\s*(.*)/

    
    def initialize(text, namespace = nil)
      @text = text
      @namespace = namespace
    end
    
    # gets contents of the method call
    def call_content
      return @text.match(QUOTES_REGEX) ? $2 : nil
    end
    

    # gets content of gettext message
    def content_gettext
      if content = call_content
        content.gsub!(VARIABLES_REGEX, '{{\1}}')
      else
        puts "No content: " + @text
      end
      return content
    end
    
    # Returns the part after the method call, 
    # _('aaa' % :a => 'sdf', :b => 'agh') 
    # return :a => 'sdf', :b => 'agh'
    def variable_part
      @variable_part ||= @text.match(VARIABLES_REGEX) ? $1 : nil
    end
    
    # Extract the variables out of a gettext variable part
    # We cannot simply split the variable part on a comma, because it
    # can contain gettext calls itself.
    # Example: :a => 'a', :b => 'b' => [":a => 'a'", ":b => 'b'"]
    # TODO clean up if it's possible
    def get_variables_splitted
      return if variable_part.nil? 
      in_double_quote = in_single_quote = false
      method_indent = 0  
      s = 0
      vars = []
      variable_part.length.times do |i|
        token = variable_part[i..i]
        in_double_quote = !in_double_quote if token == "\""
        in_single_quote = !in_single_quote if token == "'"
        method_indent += 1 if token == "("
        method_indent -= 1 if token == ")"
        if (token == "," && method_indent == 0 && !in_double_quote && !in_single_quote) || i == variable_part.length - 1
          e = (i == variable_part.length - 1) ? (i ) : i - 1
          vars << variable_part[s..e]
          s = i + 1
        end
      end
      return vars
    end
    
    # Return a array of hashes containing the variables used in the
    # gettext call.
    def variables
      @variables_cached ||= begin
        vsplitted = get_variables_splitted
        return nil if vsplitted.nil?
        vsplitted.map! do |variable| 
          res = variable.match(VARIABLE_REGEX)
          value = GettextI18nConvertor.string_to_i18n(res[2], @namespace)
          {:name => res[1], :value => value}
        end
      end
    end
    
    # After analyzing the variable part, the variables
    # it is now time to construct the actual i18n call
    def to_i18n
      id = @namespace.consume_id!
      @namespace.ids[id] = content_gettext
      output = "t(:%s, %s%s)"
      if vars = self.variables
        vars.map! {|var| ":%s => %s" % [var[:name], var[:value]]}
        vars = vars.join(', ') + ', '
      end
      return output % [id, vars, @namespace.to_i18n_scope]
    end
    
    # Takes the gettext calls out of a string and converts
    # them to i18n calls
    def self.string_to_i18n(text, namespace)
      s = self.indexes_of(text, /_\(/)
      e = self.indexes_of(text, /\)/)
      r = self.indexes_of(text, /\(/)
      
      indent, indent_all,startindex, endinde, methods  = 0, 0, -1, -1, []
      
      output = ""
      level = 0
      gettext_blocks = []
      text.length.times do |i|
        token = text[i..i]
       
        in_gettext_block = gettext_blocks.size % 2 == 1
        if !in_gettext_block
          if ! /_\(/.match(token + text[i+1..i+1]).nil?
            gettext_blocks << i
            level = 0
          end
        else # in a block
          level += 1 if ! /\(/.match(token).nil? && gettext_blocks[gettext_blocks.length - 1] != i - 1
          gettext_blocks << i if level == 0 && /\)/.match(token)
          level -= 1 if /\)/.match(token) && level != 0
        end
      end
      
      i = 0
      output = text.dup
      offset = 0
      
      (gettext_blocks.length / 2).times do |i|
        
        s = gettext_blocks[i * 2]
        e = gettext_blocks[i * 2 + 1]
        to_convert = text[s..e]
       
        converted_block = GettextI18nConvertor.new(to_convert, namespace).to_i18n
        g = output.index(to_convert) - 1
        
        h = g + (e-s) + 2
        output = output[0..g] + converted_block + output[h..output.length]
      end
      output
    end
    
    
   
     
    
    
    private 
    
    # Finds indexes of some pattern(regexp) in a string
    def self.indexes_of(str, pattern)
      indexes = []
      str.length.times do |i|
        match = str.index(pattern, i)
        indexes << match if !indexes.include?(match)
      end
      indexes
    end
    
  end
end
