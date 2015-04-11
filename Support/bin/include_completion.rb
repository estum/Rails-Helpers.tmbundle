require "rubygems"
require "pathname"
require 'active_support/core_ext/string/inflections'

proj = Pathname.new(ENV["TM_PROJECT_DIRECTORY"])
prior, items, ns, nsmatch = [], [], nil, nil
source = Pathname.new(ENV['TM_FILEPATH']).sub_ext("").relative_path_from(proj)

Pathname.glob(proj / "app/**/concerns") do |conc|
  unless ns
    r = conc.dirname.relative_path_from(proj)
    source.ascend do |v|
      ns = source.relative_path_from(v).to_s.camelize if v == r
      break if ns
    end
    nsmatch = /^#{ns}::(.+)$/i if ns
  end

  Pathname.glob(conc / "**/*.rb") do |file|
    dir, bn    = file.relative_path_from(conc).split
    class_name = (dir / bn.basename(".rb")).to_s.camelize
    if nsmatch && nsmatch =~ class_name
      prior << $1
    else
      items << class_name
    end
  end
end

print "include ${1|#{(prior | items).join(?,)}|}$0"