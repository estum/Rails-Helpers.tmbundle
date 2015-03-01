require "pathname"

class NamespacedModule
  attr_accessor :namespace, :output, :module_type, :superklass, :filepath, :project_directory, :path
  
  alias_method :project, :project_directory
  
  def initialize(module_type = :module, superklass = nil)
    @module_type = module_type
    @superklass = superklass
    %w(filepath project_directory).each {|name| self.send :"#{name}=", Pathname.new(ENV["TM_#{name.upcase}"]) }
    @path = filepath.relative_path_from(project)
  end
  
  def take_trails(&block)
    path.dirname.to_s.split("/").reverse_each.each_cons(2).take_while(&block).map(&:first)
  end
  
  def namespace
    @namespace ||= take_trails do |base, next_item|
      !(next_item =~ /^app$/) && 
      !(base      =~ /^lib|controllers|helpers|models|concerns$/)
    end
  end
  
  def cur(pos = nil, *args)
    case pos
    when nil     then namespace.length
    when Numeric then curx(0, pos)
    when :x      then curx(*args)
    end
  end
  
  def curx(n = 0, after = 0)
    ((cur() + n) * 2) + after
  end
  
  def tab
    @tab ||= (ENV['TM_SOFT_TABS'] == 'YES' ? " " : "\t") * ENV['TM_TAB_SIZE'].to_i
  end
  
  def tab_and_line
    tab = self.tab
    proc {|line| "#{tab}#{line}" }
  end
  
  def module?
    module_type == :module
  end
  
  def inherits?
    !@superklass.nil?
  end
  
  def heuristic_inheritances
    case ENV['TM_DIRECTORY']
    when /controllers/ then ["ApplicationController", "ActionController::Base"]
    when /models/      then ["ActiveRecord::Base"]
    when /jobs/        then ["ActiveJob::Base"]
                       else ["ParentClass", @superklass]
    end
  end
  
  def inheritance
    return "" if module? or !inherits?
    s!([3]=>" < #{choose!([2]=>heuristic_inheritances)}")
  end
  
  def name
    "${TM_FILENAME/(?:\\A|_)([A-Za-z0-9]+)(?:\\.rb)?/(?2::\\u$1)/g}".freeze    
  end
  
  def capitalize!(name)
    name.gsub!(/(?:_)?([a-z0-9]*)/i){$1.capitalize}    
  end
  
  def s(*args)
    format = "%d"
    if block_given?
      format = "{%d#{args[0]}}"
      args = yield
    end
    "$#{sprintf(format, *args)}"
  end
  
  def s!(opts = {})
    pos, choise = *opts.to_a[0]
    s(":%s"){[ cur(*pos), choise ]}
  end
  
  def choose!(opts = {})
    pos, choises = *opts.to_a[0]
    return s! pos=>choises[0] unless choises.length > 1
    s("|%s|"){[ cur(*pos), choises.join(',') ]}
  end
  
  def type_choise(*args)
    choose! [:x,*args] => [:class, :module]
  end
  
  def tabbed_inner
    @output.each_line.map(&tab_and_line)
  end
  
  # module ${n+2:${TM_FILENAME/../..$1/}${n+4: < ${n+3|${ParentClass}|}}}
  # ··TAB ⇥
  # end
  def declare!
    @output = <<-TM_SNIPPET.gsub(/^\s+\|/, '')
      |#{module_type} #{s!([1]=>name)}#{inheritance}
      |#{tab}#{s(0)}
      |end
    TM_SNIPPET
  end
  
  def wrap_inner!(name, i)
    @output = <<-TM_SNIPPET.gsub(/^\s+\|/, '')
      |#{type_choise(-i,-1)} #{s!([:x,-i]=>name)}
      |#{tabbed_inner}
      |end
    TM_SNIPPET
  end
  
  def snippet
    declare!
    namespace.each.with_index do |name, i|
      capitalize! name
      wrap_inner! name, i
    end
    @output
  end
end