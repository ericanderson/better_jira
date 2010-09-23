# -*- encoding: utf-8 -*-
# Copyright (c) 2010 Eric Anderson
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'better_jira/version'

Gem::Specification.new do |s|
  s.name            = 'better_jira'
  s.version         = BetterJira::VERSION
  s.platform        = Gem::Platform::RUBY
  s.authors         = ['Eric Anderson']
  s.email           = ['eric@ericanderson.us']
  s.homepage        = 'http://github.com/ericanderson/better_jira'
  s.summary         = 'Yet Another Jira Gem'
  
  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_runtime_dependency('httpclient', '>=2.1.5.2')
  s.add_runtime_dependency('soap4r', '1.5.8')
  s.add_development_dependency('rake')
  
  s.files        = Dir['{lib}/**/*']
  s.require_path = 'lib'
end