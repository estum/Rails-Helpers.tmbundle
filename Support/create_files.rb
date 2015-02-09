$:.push(File.join(ENV['TM_BUNDLE_SUPPORT'], "lib")) unless $:.include?(File.join(ENV['TM_BUNDLE_SUPPORT'], "lib"))
require 'active_support/inflector'
require File.join(ENV['TM_BUNDLE_SUPPORT'], "require_support.rb")

shared_lib "escape"
bundle_lib "core_ext/string"

module CreateFiles
  @extentions = {
    :views       => %w(.erb .slim .haml),
    :js          => %w(.coffee, .js),
    :stylesheets => %w(.scss .less .sass .css),
    :locales     => %w(.yaml .rb),
    :controllers => %w(.rb)
  }

  @pathes = {
    :views       => 'app/views',
    :js          => 'app/assets/javascripts',
    :stylesheets => 'app/assets/stylesheets',
    :controllers => 'app/controllers',
    :models      => 'app/models',
    :helpers     => 'app/helpers',
    :mailers     => 'app/mailers',
    :initializer => 'config/initializers',
    :locales     => 'config/locale'
  }
  
  def self.create_file(filename, type, *argv)
    @argv     = [argv].flatten.first
    @filename = filename
    @type     = type
    
    @filename ||= "untitled"
    # @type ||= ".rb"
    
    @current_path        = ENV['TM_FILEPATH']
    @current_dir         = ENV['TM_DIRECTORY']
    @current_project_dir = ENV['TM_PROJECT_DIRECTORY']
    @extname             = set_extname
    @dir                 = @argv[:dir].nil? ? set_path : [@pathes[@type], @argv[:dir]].join('/')
    @abs_dir             = File.join(@current_project_dir, @dir)
    
    Dir.mkpath(@abs_dir) if !Dir.exists?(@abs_dir)
    
    @fullpath = File.join(@abs_dir, "#{@filename}#{@extname}")
    
    file = !File.exist?(@fullpath) ? File.new(@fullpath, 'w+') : File.open(@fullpath, 'w+')
    TextMateRailsFile.new(file)
  end
  
  def self.set_extname
    current_ext = File.extname(@current_path)
    
    return '.rb'       if @extentions[@type].nil?
    return current_ext if current_ext.in?(@extentions[@type])
    @extentions[@type].first
  end
  
  def self.set_path
    current_path  = @current_dir - "#{@current_project_dir}/"
    selected_path = get_selected_path    
    path          = current_path

    if !@pathes[@type].nil?
      if !is_matches?(path)
        if selected? && is_matches?(selected_path)
          path = selected_path
        else
          path = @pathes[@type]
        end
      end
    elsif selected?
      path = selected_path
    end
      
    path
  end
  
  
  def self.is_matches?(path)
    path.start_with?(@pathes[@type])
  end
  
  def self.get_selected_path
    selected_file = ENV['TM_SELECTED_FILE']
    if selected?
      selected_file = File.dirname(selected_file) if !File.directory?(selected_file)
      selected_file = selected_file - "#{@current_project_dir}/"
    end
    selected_file
  end
  
  def self.selected?
    !ENV['TM_SELECTED_FILE'].nil? && ENV['TM_SELECTED_FILE'].start_with?(@current_project_dir)
  end
end


class TextMateRailsFile
  def initialize(file, *options)
    @file = file
    @path = File.absolute_path @file.path    
  end
  
  def open
    %x{open txmt://open/?url=file://#{e_sh @path}}
    self
  end
end