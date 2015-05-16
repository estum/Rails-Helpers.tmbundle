require "forwardable"
require File.join(ENV['TM_SUPPORT_PATH'], 'lib/current_word')
require File.join(ENV['TM_BUNDLE_SUPPORT'], 'lib/core_ext/object/blank')
require File.join(ENV['TM_BUNDLE_SUPPORT'], 'lib/core_ext/enumerable')

class String
  CLOSING_MAP = { "[" => "]", "(" => ")", "{" => "}" }.freeze
  def closing
    CLOSING_MAP[chr] || self
  end
end

module ArraySyntax
  class Toggle
    attr_accessor :input, :source, :swapped, :output

    def initialize(input)
      @input   = input
      @source  = selected? ? input : get_array_on_cursor
      @swapped = swap_syntax_of(source)     if source.present?
      @output  = if swapped.present?
        input.dup.tap do |s|
          if selected?
            s.replace(swapped)
          else
            s.slice!(@from...@to)
            s.insert(@from, swapped)
          end
        end
      end
      yield(@output)
    end

    private

    def get_array_on_cursor
      left  = Word.current_word(/^(.+?(?:\p{Ps}[wi]%|\[(?!\b)))/i, :left)
      close = left[/(?<=^%[wi])\p{Ps}|^\[/i].to_s.closing
      right = Word.current_word(/^(.+?(?:#{close.prepend(?\\)}))/, :right) if close.present?
      return unless right.present?
      @from = (ENV['TM_COLUMN_NUMBER'].to_i - left.length).pred
      @to   = (ENV['TM_COLUMN_NUMBER'].to_i + right.length).pred
      [left, right].join
    end

    def literalizer_for(items)
      klass = [SymbolLiteral, StringLiteral].
        find { |o| items.all? { |e| e =~ o.pattern } }.
        presence || NullLiteral
      klass.new
    end

    def swap_syntax_of(part)
      if /(?<=^\[)(.+?)(?=\]$)/ =~ part
        items = scan_items($1)
        literalizer_for(items).render_with(items)
      else
        if /^%(w|i)\p{Ps} *(.*?) *?\p{Pe}$/i =~ part
          is_string = $1.downcase == "w"
          s = $2.split(/(?<!\\)\s+/).map { |v| toggle_interpolation(v, is_string) }.join(", ")
          "[#{s}]"
        end
      end
    end

    def scan_items(part)
      part.split(?,).
        slice_when {|l,r| r.lstrip =~ /\A:?(["']?).+?(?!\1)\z/ || l.rstrip =~ /\A[^'"]+?['"]?\z/ }.
        map { |a| a.join(?,).strip.gsub(' ', '\\ ') }
    end

    def toggle_interpolation(value, is_string)
      if value.start_with?('#')
        value[/(?<=#\{)(.*?)(?=\})/, 1]
      else
        (is_string ? %Q["#{value.gsub(/\\\s/, ' ')}"] : value.to_sym.inspect)
      end
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

  class Literalizer
    extend Forwardable
    class << self; attr_accessor(:chr, :pattern); end
    delegate [:chr, :pattern] => "self.class"

    def render_with(items)
      normalized = items.map { |e| process(e) }
      "%#{@_chr || chr}(#{normalized * ' '})"
    end

    def process(e)
      e.match(pattern) { |m| m[1].empty? ? interpolate(m[2]) : m[2] }
    end

    def interpolate(e)
      @_chr ||= chr.to_s.upcase
      format('#{%s}', e)
    end
  end

  class SymbolLiteral < Literalizer
    @chr, @pattern = :i, /^(:|(?!'|"))(.+?)$/
    def process(e)
      super(e)[/^(['"]?)(.*)\1$/, 2]
    end
  end

  class StringLiteral < Literalizer
    @chr, @pattern = :w, /^('|"|(?!:))(.+?)\1$/
  end

  class NullLiteral < Literalizer
    def render_with(*); end
  end
end