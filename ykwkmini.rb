#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# YukiWikiMini.rb Version 1.0.0
#
# ykwkmini.rb - Yet another WikiWikiWeb clone.
#
# Copyright (C) 2000,2001 by Hiroshi Yuki.
# <hyuki@hyuki.com>
# http://www.hyuki.com/yukiwiki/
#
# Copyright (C) 2016 by Takashi Maekawa
# <takachin+github@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
##############################
require 'cgi'
require 'yaml/store'
$db = YAML::Store.new('./ykwkmini.yaml')

$thisurl    = 'ykwkmini.rb'
$frontpage  = 'FrontPage'
$indexpage  = 'Index'
$errorpage  = 'Error'
$WikiName   = '([A-Z][a-z]+([A-Z][a-z]+)+)'
$thisurl    = 'ykwkmini.rb'
$editchar   = '?'
$titlecolor = '#FFFFCC'
$bgcolor    = 'white'
$naviedit   = 'Edit'
$naviwrite  = 'Write'
$naviedit   = 'Edit'
$naviindex  = 'Index'
$msgdeleted = ' is deleted.'
$cols = 80
$rows = 20
$debug = false
$style = <<"EOD"
<style type='text/css'>
<!--
pre { line-height:130% }
a { text-decoration: none }
a:hover { text-decoration: underline }
body { background-color: #{$bgcolor} }
table#title { background-color: #{$titlecolor}; border: none; width: 100%;}
-->
</style>
EOD

def main
  cgi = CGI.new
  params = cgi.params.dup
  params.each_key{|key|
    if /^(#{$WikiName})$/ =~ key
        cgi.params['mycmd'] = ["read"]
        cgi.params['mypage'] = [$1]
        break
    end
  }
  if cgi['mycmd']    == "read"
    do_read(cgi)
  elsif cgi['mycmd'] == "edit"
    do_edit(cgi)
  elsif cgi['mycmd'] == "write"
    do_write(cgi)
  elsif cgi['mycmd'] == "index"
    do_index(cgi)
  else
    cgi.params['mypage'] = [$frontpage]
    do_read(cgi)
  end
end

def load_content(mypage)
  content = nil
  $db.transaction do
    content = $db[mypage]
  end
  content = "" if content == nil
  content
end

def wirte_content(mypage,content)
  $db.transaction do
    $db[mypage] = content
  end
end

def delete_content(mypage)
  $db.transaction do
    $db.delete(mypage)
  end
end

def do_read(cgi)
  content = load_content(cgi['mypage'])
  cgi.out("type" => "text/html" ,"charset" => "UTF-8") {
    print_header(cgi['mypage'],true) +
    print_content(content) +
    print_footer +
    debug(cgi)
  }
end

def do_edit(cgi)
  content = load_content(cgi['mypage'])
  form_html = <<"EOD"
      <form action="#{$thisurl}" method="post">
          <input type="hidden" name="mycmd" value="write">
          <input type="hidden" name="mypage" value="#{cgi['mypage']}">
          <textarea cols="#{$cols}" rows="#{$rows}" name="mymsg" wrap="virtual">#{content}</textarea><br />
          <input type="submit" value="#{$naviwrite}">
      </form>
EOD
  cgi.out("type" => "text/html" ,"charset" => "UTF-8") {
    print_header(cgi['mypage'],true) +
    form_html +
    print_footer +
    debug(cgi)
  }
end

def do_index(cgi)
  index_html = "<ul>"
  $db.transaction do
    $db.roots.each{|k, v|
      index_html += "<li><a href=\"#{$thisurl}?#{k}\">#{k}</a></li>"
    }
  end
  index_html += "</ul>"
  cgi.out("type" => "text/html" ,"charset" => "UTF-8") {
    print_header($indexpage, false) +
    index_html +
    print_footer +
    debug(cgi)
  }
end

def do_write(cgi)
  if (!cgi["mymsg"].empty?)
      wirte_content(cgi["mypage"],cgi["mymsg"])
      content = load_content(cgi['mypage'])
      cgi.out("type" => "text/html" ,"charset" => "UTF-8") {
        print_header(cgi['mypage'],true) +
        print_content(content) +
        print_footer +
        debug(cgi)
      }
  else
      delete_content(cgi["mypage"])
      cgi.out("type" => "text/html" ,"charset" => "UTF-8") {
        print_header(cgi['mypage']+$msgdeleted,false) +
        print_footer +
        debug(cgi)
      }
  end
end

def print_header(title, canedit)
  edit_html_link = ''
  edit_html_link = "<a href=\"#{$thisurl}?mycmd=edit&mypage=#{title}\">#{$naviedit}</a> | " if canedit

  header = <<"EOS"
<html>
  <head><title>#{title}</title>#{$style}</head>
  <body>
      <table id="title">
          <tr valign="top">
              <td><b><tt>#{title}</tt></b></td>
              <td align="right"><tt>
                  <a href="#{$thisurl}"?"#{$frontpage}">#{$frontpage}</a> |
                  #{edit_html_link}
                  <a href="#{$thisurl}?mycmd=index">#{$naviindex}</a> |
                  <a href="http://www.hyuki.com/yukiwiki/">YukiWikiMini</a>
              </tt></td>
          </tr>
      </table>
EOS
header
end

def print_content(text)
  text = CGI.escapeHTML(text)
  text = text.gsub(/(mailto|http|https|ftp):[\x21-\x7E]*/){|word| make_link(word)}
  text = text.gsub(/#{$WikiName}/) {|word| make_link(word) }
  "<pre>#{text}</pre>"
end

def print_footer
  "</body></html>"
end

def make_link(text)
  content = load_content(text)
  return "<a href=\"#{text}\">#{text}</a>" if /^(http|https|ftp):/ =~ text
  return "<a href=#{$thisurl}?#{text}>#{text}</a>" if content != nil
  "#{text}<a href=#{$thisurl}?mycmd=edit&mypage=#{text}>#{$editchar}</a>"
end

def debug(cgi)
  return "" unless $debug
  cgi.inspect
end

main
