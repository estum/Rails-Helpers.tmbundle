require File.join(ENV['TM_BUNDLE_SUPPORT'], 'lib/core_ext/object/blank.rb')
require File.join(ENV['TM_BUNDLE_SUPPORT'], 'lib/core_ext/enumerable')

class String
  CLOSING_MAP = { "[" => "]", "(" => ")", "{" => "}" }.freeze
  def closing; CLOSING_MAP[chr] || self; end
end

class ArraySyntax
  attr_accessor :input_text

  def self.call(value)
    new.call(value)
  end

  def call(value)
    @input_text = value
    selected? ? print_for_selection! : print_for_line!
  end

  SwapToLiteral = Struct.new(:chr, :pattern) do
    def call(items)
      return unless items.all? { |e| e =~ pattern }
      @converted ||= items.map { |e| process(e) }
      "%#{@_chr || chr}(#{@converted * ' '})"
    end

    def process(e)
      e.match(pattern) { |m| m[1].empty? ? interpolate(m[2]) : m[2] }
    end

    def interpolate(e)
      @_chr ||= chr.to_s.upcase
      format('#{%s}', e)
    end
  end

  class SymbolLiteral < SwapToLiteral
    def initialize; super(:i, /^(:|(?!'|"))(.+?)$/); end
  end

  class StringLiteral < SwapToLiteral
    def initialize; super(:w, /^('|"|(?!:))(.+?)\1$/); end
  end

  protected

  def all_items_matches?(items, pattern)
    items.all? { |i| pattern === i }
  end

  def ary_match(part)
    if /(?<=^\[)(.+?)(?=\]$)/ =~ part
      ary = scan_items($1)
      SymbolLiteral.new.(ary) || StringLiteral.new.(ary)
    else
      if part =~ /^%(w|i)\p{Ps} *(.*?) *?\p{Pe}$/i
        is_string = $1.downcase == "w"
        s = $2.split(/(?<!\\)\s+/).map { |v| toggle_interpolation(v, is_string) }.join(", ")
        "[#{s}]"
      end
    end
  end

  def scan_items(part)
    part.split(?,).
      slice_when {|l,r| /\A\s*:?(["']).+?(?!\1)\z/ =~ r || /\A.+?['"]\s*\z/ =~ l }.
      map {|a| a.join(?,).strip.gsub(' ', '\\ ') }
  end

  def toggle_interpolation(value, is_string)
    if value.start_with?('#')
      value[/(?<=#\{)(.*?)(?=\})/, 1]
    else
      (is_string ? %Q["#{value.gsub(/\\\s/, ' ')}"] : ":#{value}")
    end
  end

  ARRAY_LEFT = /.*(%[wi]\p{Ps}|(?<!%[wi])\[)(.*)$/i
  ARRAY_RIGHT = /^(.+)(?=\p{Pe})\p{Pe}/

  def ary_of_cur(line, cur)
    left  = line[0, cur].scan(ARRAY_LEFT).flatten
    close = left[0] =~ /^%[wi](\p{Ps})/i ? $1.closing.prepend(?\\) : '\]'
    right = line[cur..-1].scan(/^(.*?)(#{close})/).flatten
    left.join + right.join
  end

  def print_for_line!
    input_text.lines.each_with_index do |input_line, n|
      output = if line?(n)
        matched_array = ary_of_cur(current_line, ENV['TM_LINE_INDEX'].to_i)
        if (matched_array.length > 0) && (output = ary_match(matched_array))
          input_line.sub(matched_array, output)
        end
      end
      print(output.presence || input_line)
    end
  end

  def print_for_selection!
    output = ary_match(input_text)
    print(output.presence || input_text)
  end

  def selected?
    ENV['TM_SELECTED_TEXT'].present?
  end

  def line?(n)
    ENV['TM_LINE_NUMBER'].to_i == n.next
  end

  def current_line
    ENV['TM_CURRENT_LINE']
  end
end