class NamespacedModule
  attr_accessor :namespace, :output, :module_type, :superklass
  
  def initialize(module_type = :module, superklass = nil)
    @module_type = module_type
    @superklass = superklass
  end
  
  def namespace
    @namespace ||= begin
      trails = ENV['TM_DIRECTORY'].split('/') - ENV['TM_PROJECT_DIRECTORY'].split('/')
      trails.reverse!
      trails.take_while.with_index do |basename, index|
        !(trails[index.next].to_s =~ /^app$/) && !(basename =~ /^concerns|controllers|helpers|models|lib$/)
      end
    end
  end
  
  def tab
    @tab ||= (ENV['TM_SOFT_TABS'] == 'YES' ? " " : "\t") * ENV['TM_TAB_SIZE'].to_i
  end
  
  def superklasses
    _klasses = case ENV['TM_DIRECTORY']
    when /controllers/ then ["ApplicationController", "ActionController::Base"]
    when /models/ then ["ActiveRecord::Base"]
    else ["ParentClass", @superklass]
    end
    (_klasses.length > 1) ? "|#{_klasses.join(',')}|" : ":#{_klasses[0]}"
  end
  
  def superclass_snippet
    return "" if (module_type == :module) || @superklass.nil?
    cursor = namespace.length * 2
    "${#{cursor + 3}: < ${#{cursor + 2}#{superklasses}}}"
  end
  
  def snippet
    output = begin
%Q<#{module_type} ${#{(namespace.length * 2).next}:${TM_FILENAME/(?:\\A|_)([A-Za-z0-9]+)(?:\\.rb)?/(?2::\\u$1)/g}}#{superclass_snippet}
#{tab}$0
end>
    end
    
    namespace.each.with_index do |name, index|
      tabbed_output = output.each_line.map{|l| "#{tab}#{l}" }.join('')
      cursor = (namespace.length - index) * 2
      name.gsub!(/(?:_)?([A-Za-z\d]*)/i) { $1.capitalize }
      output = begin
%Q<${#{cursor - 1}|class,module|} ${#{cursor}:#{name}}
#{tabbed_output}
end>
      end
    end
    
    output
  end
end