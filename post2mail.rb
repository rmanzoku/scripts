#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nkf'
require 'optparse'

class Post2Mail
  class CLI
    def parse_options(argv = ARGV)
      op = OptionParser.new

      self.class.module_eval do
        define_method(:usage) do |msg = nil|
          puts op.to_s
          puts "error: #{msg}" if msg
          exit 1
        end
      end

      opts = {
        address: 'email-smtp.us-east-1.amazonaws.com',
        port: '587',
        user: ENV['SMTP_USER'],
        password: ENV['SMTP_PASS'],
        from: ENV['SMTP_FROM'],
        to: '',
        subject: 'post2mail',
      }

      op.on('-a', '--address VALUE', "SMTP host address (default: #{opts[:address]})") do |v|
          opts[:address] = v
      end

      op.on('-P', '--port VALUE', "SMTP port (default: #{opts[:port]})") do |v|
        opts[:port] = v
      end

      op.on('-u', '--user VALUE', "SMTP user (default: ENV['SMTP_USER'])") do |v|
        opts[:user] = v
      end
      op.on('-p', '--password VALUE', "SMTP password (default: ENV['SMTP_PASS'])") do |v|
        opts[:password] = v
      end

      op.on('-f', '--from VALUE', "Mail from (default: ENV['SMTP_FROM']") do |v|
        opts[:from] = v
      end
      op.on('-t', '--to VALUE', "Mail to") do |v|
        opts[:to] = v
      end

      op.on('-s', '--subject VALUE', "SMTP port (default: #{opts[:subject]})") do |v|
        opts[:subject] = v
      end

      op.banner += ''

      begin
        args = op.parse(argv)
      rescue OptionParser::InvalidOption => e
        usage e.message
      end

      if opts[:to] == ''
        usage "Option 'to' must be set"
      end

      [opts, args]
    end

    def run
      opts, _args = parse_options
      domain = opts[:from].split('@')[1]
      input = STDIN.read
      mail_str = <<~ROW
                  From: #{opts[:from]}
                  To: #{opts[:to]}
                  Subject: #{NKF.nkf('-WMm0j', opts[:subject])}
                  Date: #{Time.now.strftime('%a, %d %b %Y %X %z')}
                  Mime-Version: 1.0
                  Content-Type: text/plain; charset=ISO-2022-JP
                  Content-Transfer-Encoding: 7bit

                  #{input}
                  ROW

      ssl_context = Net::SMTP.default_ssl_context

      smtp = Net::SMTP.new(opts[:address], opts[:port])
      smtp.enable_starttls(ssl_context)
      smtp.start(domain, opts[:user], opts[:password], :login) do |s|
        s.send_message(mail_str, opts[:from], opts[:to])
      end
    end
  end
end

if $0 == __FILE__
  Post2Mail::CLI.new.run
end
