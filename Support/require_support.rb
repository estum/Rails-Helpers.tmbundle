@support = {
  bundle: ENV['TM_BUNDLE_SUPPORT'],
  shared: ENV['TM_SUPPORT_PATH']
}

def bundle_lib(script)
  require_support :lib, script
end

def bundle_bin(script)
  require_support :bin, script
end

def shared_lib(script)
  require_support :shared, :lib, script
end

def shared_bin(script)
  require_support :shared, :bin, script
end

def require_support(*args)
  script = args.slice!(-1)
  dir    = args.slice!(-1)
  bundle = args.last || :bundle
  
  if File.extname(script).empty?
    script << ".rb"
  end
  
  require File.join(@support[bundle], dir.to_s, script)
end