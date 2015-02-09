#!/usr/bin/env ruby18

require 'time'
require File.join(ENV['TM_SUPPORT_PATH'], 'lib/textmate')
require File.join(ENV['TM_SUPPORT_PATH'], 'lib/ui')

module OpenMigration
  def self.list_latest_migrations_from_path(path)
    migrations = File.directory?(path) ? Dir[File.join(path, '*.rb')].reverse.first(50) : []
    
    return migrations.map do |migration|
      filename = File.basename migration
      migration_time = Time.parse("#{filename[0..3]}-#{filename[4..5]}-#{filename[6..7]} #{filename[8..9]}:#{filename[10..11]}:#{filename[12..13]}").strftime("%b %d, %Y")
      migration_name = filename[15..-1]
      {
        'title'    => "#{migration_name} — #{migration_time}",
        'filename' => migration
      }
    end
  end
  
  def self.go
    path = "#{ENV['TM_PROJECT_DIRECTORY']}/db/migrate"
    choises = OpenMigration.list_latest_migrations_from_path(path)
    # puts choises
    choise = TextMate::UI.menu(choises)
    TextMate.go_to :file => choise['filename']
  rescue
    nil
  end
end

OpenMigration.go
!!!