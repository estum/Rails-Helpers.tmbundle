lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rubygems"
require "tm_bundle_support"

TMBundle.eager_load!