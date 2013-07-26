require 'rkelly'
require 'flay'

class Flay
  def self.load_plugins
    %w(js erb haml)
  end

  def self.options_js o, options
    o.separator nil
    o.separator "Persistence options:"
    o.separator nil
    o.on("-e", "--exclude PATH", String,
            "Path to file with regular expressions for files to be skipped",
            "  use '-e default' to skip jquery, jquery-ui, *.min.js and versioned file names") do |p|
        p = File.dirname(__FILE__) + "/../data/flay_js_exclude" if p == 'default'
        rexps = File.readlines(p).
            map(&:strip).
            reject(&:empty?).
            map{ |s| Regexp.new s }
        options[:exclude] = Regexp.union(rexps) unless rexps.empty?
    end
    o.on("-j", "--javascript",
         "Run flay in javascript mode",
         "  (in addition to *.js process javascript fragments in *.erb and *.haml ") do
      @@plugins = %w(js haml erb)
      alias_method :null_erb, :process_erb
      alias_method :process_erb, :do_erb
      alias_method :sexp_to_erb, :sexp_to_js
      alias_method :null_haml, :process_haml if respond_to? :process_haml
      alias_method :process_haml, :do_haml
      alias_method :sexp_to_haml, :sexp_to_js
    end
  end

  def do_haml(file)
    return nil if option[:exclude] && option[:exclude] =~ file
    haml = File.read file
    return nil if haml !~ /$\s*:javascript/

    blocks = js_haml_blocks(haml, file)
    return nil if blocks.empty?
    sexp = s(:block, *blocks)
    sexp.line 1
  end

  def js_haml_blocks(haml, file)
    lines = haml.lines.to_a
    blocks = []
    off = 0
    while lines && (off = lines.find_index{ |s| s =~ /^(\s*):javascript\s*$/})
      indent = $1.size
      offset = off + 1
      js = ''
      while (line = lines[offset]) &&
        ( (line =~/^(\s*)[^\s]/ && $1.size > indent) || line.strip.empty? )
        js << line
        offset += 1
      end
      blocks << js_sexp(js, file, off + 1)
      lines = lines[offset..-1]
    end
    blocks
  end

  def do_erb(file)
    return nil if option[:exclude] && option[:exclude] =~ file
    return process_js(file) if file =~ /\.js\./
    erb = File.read file
    return nil if erb !~ /<\s*script/i

    blocks = js_erb_blocks(erb, file)
    return nil if blocks.empty?

    sexp = s(:block, *blocks)
    sexp.line 1
  end

  def js_erb_blocks(erb, file)
    lines = erb.lines.to_a
    blocks = []
    offset = 0
    while lines && (off = lines.find_index{ |s| s =~ /<\s*script/i })
      str = lines.join
      str =~ /(<\s*script[^>]*>[\n\s]*)(.*?)(<\s*\/\s*script\s*>[\n\s]*)/im
      off = off + $1.count("\n")
      blocks << js_sexp($2, file, offset + off)
      offset += ($2 + $3).count("\n") + off + 1
      lines = lines[offset .. -1]
    end
    blocks
  end

  def process_js(file)
    return nil if option[:exclude] && option[:exclude] =~ file
    js = File.read file
    js_sexp(js, file, 0)
  end

  def js_sexp(js, file, offset)
    js = unerb(js) if file =~ /\.erb$/
    js = uninterpolate(js) if file =~ /\.haml$/

    asx = RKelly::Parser.new.parse(js, file)
    puts js if asx.nil? && option[:verbose]
    raise "JS syntax error in #{file}" unless asx
    if option[:diff]
      @asx ||= Hash.new{|h,k| h[k] = []}
      @asx[file] << asx
    end
    fixed(asx.to_real_sexp, offset)
  end

  def fixed(sexp, offset = 0)
    sexp.line ||= 0
    sexp.line += offset
    file = sexp.file
    sexp.deep_each do |s|
      s.line ||= 0
      s.line += offset
      file ||= s.file
    end
    sexp.file = file
    sexp.deep_each do |s|
      s.file = file
    end
    sexp
  end

  def unerb(js)
    js.gsub(/(<%=.*?%>)/) do |erb|
      erb.gsub(/[^\w]+/,'_')
    end
  end

  def uninterpolate(js)
    # WOW!!!!!
    js.gsub(/(\#{[^{}]*})/) do |str|
      str.gsub(/[^\w]+/,'_')
    end.gsub(/(\#{.*})/) do |str|
      str.gsub(/[^#]({[^{}]*})/) do |sub|
        sub.gsub(/[^\w]+/,'_')
      end.gsub(/(\#?{[^{}]*})/) do |sub|
        sub.gsub(/[^\w]+/,'_')
      end
    end
  end

  def sexp_to_js(sexp)
    @asx[sexp.file].each do |asx|
      asx.each do |sa|
        return sa.to_ecma if sa.to_real_sexp == sexp
      end
    end
    'Conversion to javascript failed'
  end
end
