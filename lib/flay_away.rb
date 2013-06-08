require_relative 'flay_away/version'
require 'action_view'
require 'rkelly'

class Sexp
  def mline(pp = true)
    ll = []
    self.each_sexp do |s|
      ll << s.mline || s.line
    end
    ll << @mline unless self.first == :when
    ll.compact.max
  end

  def mline=(val)
    @mline = val
  end
end

module FlayAway
  # 2.3.0 bug fix
  def fixed_n_way_diff *data
    comments = []
    codes    = []

    split_and_group_non_empty(data).each do |subdata|
      n = subdata.find_index { |s| s !~ /^#/ }

      codes << subdata[n..-1] if n
      comments << subdata[0..n-1] if n > 0
    end

    comments = collapse_and_label_no_ws(pad_with_empty_strings(comments)) unless comments.empty?
    codes    = collapse_and_label(pad_with_empty_strings(codes)) unless codes.empty?

    (comments + codes).flatten.join("\n")
  end
  
  def split_and_group_non_empty_no_ws ary # :nodoc:
    ary.each_with_index.map { |s, i|
      c = (?A.ord + i).chr
      s.scan(/^.*/).select{ |l| l !~ /^\s*$/ }.map { |s2|
        s2.group = c
        s2
      }
    }
  end

  def collapse_and_label_no_ws ary # :nodoc:
    ary[0].zip(*ary[1..-1]).map { |lines|
      if lines.map{|l| l.gsub(/\s+/,' ').strip}.uniq.size == 1 then
        "   #{lines.first}"
      else
        lines.reject { |l| l.empty? }.map { |l| "#{l.group}: #{l}" }
      end
    }
  end

  ##
  # Output the report. Duh.

  def report_away prune = nil
    analyze

    puts "Total score (lower is better) = #{self.total}"

    if option[:summary] then
      puts

      self.summary.sort_by { |_,v| -v }.each do |file, score|
        puts "%8.2f: %s" % [score, file]
      end

      return
    end

    count = 0
    sorted = masses.sort_by { |h,m|
      [-m,
       hashes[h].first.file,
       hashes[h].first.line,
       hashes[h].first.first.to_s]
    }
    sorted.each do |hash, mass|
      nodes = hashes[hash]
      next unless nodes.first.first == prune if prune
      puts

      same = identical[hash]
      node = nodes.first
      n = nodes.size
      match, bonus = if same then
                       ["IDENTICAL", "*#{n}"]
                     else
                       ["Similar",   ""]
                     end

      if option[:number] then
        count += 1

        puts "%d) %s code found in %p (mass%s = %d)" %
         [count, match, node.first, bonus, mass]
      else
        puts "%s code found in %p (mass%s = %d)" %
         [match, node.first, bonus, mass]
      end

      nodes.sort_by { |x| [x.file, x.line] }.each_with_index do |x, i|
        if option[:diff] then
          c = (?A.ord + i).chr
          extra = " (FUZZY)" if x.modified?
          puts "  #{c}: #{x.file}:#{minmax(x)}#{extra}"
          puts x.to_s
        else
          extra = " (FUZZY)" if x.modified?
          puts "  #{x.file}:#{minmax(x)}#{extra}"
        end
      end

      if option[:diff] then
        puts
        puts fixed_n_way_diff(*nodes.map { |s| File.readlines(s.file)[s.line - 1, s.mline - s.line + 1].join("\n") })
      end
    end
  end

  def minmax(sexp)
    mm = [sexp.line, sexp.line]
    sexp.each_sexp do |s|
      omm = minmax(s)
      mm.first = [mm.first, omm.first].compact.max 
      mm.last = [mm.last, omm.last].compact.max
    end
  end

  def process_erb(file)
    return process_js(file) if file =~ /\.js\./
    raise 'css' if file =~ /\.s?[ac]ss\./
    raise 'coffee' if file =~ /\.coffee\./
    erb = File.read file
    st = Struct.new(:source, :mime_type).new(erb, 'text/html')
    ruby = ActionView::Template::Handlers::ERB.call(st)
    RubyParser.new.process(ruby, file)
  end

  def process_js(file)
    raise 'Minified js' if file =~ /\.min\.js$/
    raise 'Versioned - most probably copy' if file =~/\d\.\d/
    js = File.read file
    raise 'Too big' if js.size > 50000
    asx = RKelly::Parser.new.parse(unerb(js), file)
    raise 'Syntax error' unless asx
    fixed(asx.to_real_sexp)
  end
  
  def fixed(sexp)
    sexp.line ||= 0
    file = sexp.file
    sexp.deep_each do |s|
      s.line ||= 0
      s.file = file
    end
    sexp
  end

  def unerb(js)
    js.gsub(/(<%=.*%>)/) do |erb|
      "'#{erb.gsub("'",'"')}'"
    end
  end
end
