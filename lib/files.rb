# GettextToI18n
module GettextToI18n
  class Files
    
    PATH_PAIRS = {
      'all' => ['app/**', '*.{erb,builder,rhtml}'],
      'controller' => ['app/controllers', '*.rb'],
      'view' => ['app/views', '**/*.{erb,builder,rhtml}'],
      'lib' => ['lib', '**/*.rb'],
      'helper' => ['app/helpers', '*.rb'],
      'model' => ['app/models', '*.rb']
    }.freeze
    CONTEXTS = PATH_PAIRS.keys.freeze
    CONTEXTS_REGEX = Regexp.new("(%s)_files" % CONTEXTS.join('|')).freeze
    
    private 
    # dynamicaly generates files arrays from path pairs
    def self.method_missing(method_id)
      method_id.to_s =~ CONTEXTS_REGEX
      Dir[File.join(RAILS_ROOT, PATH_PAIRS[$1])]

    end

  end
end
