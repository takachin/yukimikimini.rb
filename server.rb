#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'webrick'
opts  = {
  :BindAddress    => '0.0.0.0',
  :Port           => '8080',
  :DocumentRoot   => './',
  :CGIInterpreter => RbConfig.ruby
}

server = WEBrick::HTTPServer.new(opts)
server.mount('/ykwkmini.rb', WEBrick::HTTPServlet::CGIHandler,  'ykwkmini.rb')
Signal.trap(:INT){ server.shutdown }
server.start
