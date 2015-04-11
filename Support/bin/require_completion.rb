require "digest/md5"
require "pathname"
require "find"

class RequireCompletion
  def initialize
    @pattern      = /\A#{Regexp.escape(ENV["TM_CURRENT_WORD"].to_s)}/
    @project_path = Pathname.new(ENV["TM_PROJECT_DIRECTORY"])
    @project_id   = Digest::MD5.hexdigest(ENV["TM_PROJECT_DIRECTORY"])

    @load_paths   = read_cached(:load_paths) { |o| cached_load_paths.mtime >= max_mtime_in_project(o) && o } || store_load_paths!

    if cached_list.exist? && cached_list.mtime >= [gemfile_mtime, max_mtime_in_project].max
      @list = cached_list.read.split("\n")
    else
      @list = store_list!
    end
  end

  attr_accessor :load_paths, :list

  def cached_load_paths
    @cached_load_paths ||= Pathname("/tmp/.tm-#{@project_id}-load_paths")
  end

  def cached_list
    @cached_list ||= Pathname("/tmp/.tm-#{@project_id}-list")
  end

  def read_cached(key)
    path = send(:"cached_#{key}")
    yield(path.read.split("\n")) if path.exist?
  end

  def gemfile_mtime
    @gemfile_mtime ||= (@project_path / "Gemfile.lock").mtime
  end

  def get_load_paths
    @load_paths = cached_load_paths.read.split("\n") if cached_load_paths.exist?
    cached_load_paths.mtime < max_mtime_in_project
    store_load_paths!
  end

  def store_load_paths!
    out = nil
    Thread.new do
      out = IO.popen(%W(bash -l -c #{get_load_path_script}), 'r+', &:read)
      cached_load_paths.write(out)
      out = out.split("\n")
    end.join
    out
  end

  def store_list!
    ary = []
    load_paths.flat_map do |base|
      next if /lib\/ruby|extensions/ =~ base
      Thread.new do
        base = Pathname(base)
        ary << Pathname.glob(base/"**/*.rb").map { |f| f.relative_path_from(base).sub_ext("").to_s }
      end
    end.each { |x| x.join if x.is_a?(Thread) }
    cached_list.write(ary.join("\n"))
    ary
  end

  def max_mtime_in_project(paths = nil)
    if @mtime.nil?
      Find.find(*filter_relative(paths || @load_paths)) do |path|
        mtime = File.mtime(path)
        @mtime = mtime if !@mtime || @mtime < mtime
        next
      end
    end
    @mtime
  end

  def filter_relative paths
    @_relative ||= begin
      _project_path = @project_path.to_s
      paths.find_all { |path| path.start_with?(_project_path) }
    end
  end

  def get_load_path_script
    rails_app_set_load_paths_duck = "Rails.application.initializers.each{|x|x.run if x.name == :set_load_path}"
    %[cd '#{@project_path.to_s}' && ruby -r./config/environment -e '#{rails_app_set_load_paths_duck}; puts \$:']
  end
end

require "#{ENV['TM_SUPPORT_PATH']}/lib/current_word.rb"
current_word = Word.current_word('a-zA-Z0-9\/', :both)
regexp = current_word.length > 0 ? /^#{Regexp.escape(current_word)}.*$/i : /^.+$/
completion = RequireCompletion.new
choices = completion.list.grep(regexp)

if choices.size == 1
  print choices.first[current_word.size..-1]
else
  code = <<-RUBY
    require "#{ENV['TM_SUPPORT_PATH']}/lib/ui.rb"
    TextMate::UI.complete(#{choices.inspect}, :initial_filter => #{current_word.inspect})
  RUBY
  IO.popen(["ruby18", "-e", code]) { |io| print io.read }
end