require File.join(ENV['TM_BUNDLE_SUPPORT'], "require_support.rb")

shared_lib "escape"
bundle_lib "core_ext/string"

module AlternateFile
  
  def self.up
    alternate_to :prev
  end
  
  def self.down
    alternate_to :next
  end
  
  def self.prepare
    project = ENV['TM_PROJECT_DIRECTORY'].dup
    project << "/"
    
    @file = File.join(ENV['TM_DIRECTORY'], ENV['TM_FILENAME'])
    @file.without! project
    
    @list = FileList.new(@file)
  end
  
  def self.alternate_to(dest)
    prepare
    path = @list.send dest
    path_proj = projectize path
    uuid = ENV['TM_DOCUMENT_UUID']
    close_current_tab(uuid) && open_file(path_proj)
  end
  
  def self.projectize(path)
    File.join(ENV['TM_PROJECT_DIRECTORY'], path)
  end
  
  def self.close_current_tab(uuid)
    scpt_path = File.join(ENV['TM_BUNDLE_SUPPORT'], 'bin', 'close_current_tab.sh')
    %x{#{e_sh(scpt_path)} #{uuid}}
  end
  
  def self.open_file(path)
    %x{mate #{e_sh path}}
  end
  
  class FileList
    attr_accessor :list, :position
    attr_reader   :dir, :ext
    
    def initialize(filename)
      @ext  = File.extname(filename)    
      @dir  = File.dirname(filename)
      
      @list = Dir[File.join(@dir, "*#{@ext}")].sort
      @position = @list.index filename
    end
    
    def prev
      prev_index = (@position > 0) ? @position - 1 : size - 1
      change_current(prev_index)
    end
    
    def next
      next_index = (@position < size-1) ? @position + 1 : 0
      change_current(next_index)
    end
    
    def size
      @list.size
    end
    
    def change_current(pos)
      @position = pos
      current
    end
    
    def current
      @list[@position]
    end
  end
  
end