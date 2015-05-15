module Enumerable
  unless method_defined?(:slice_when)
    def slice_when(&block)
      raise ArgumentError.new("missing block") unless block
      return Enumerator.new {|e| } if empty?
      return Enumerator.new {|e| e.yield self } if length < 2

      Enumerator.new do |enum|
        ary = nil
        last_after = nil
        each_cons(2) do |before, after|
          last_after = after
          match = block.call before, after

          ary ||= []
          if match
            ary << before
            enum.yield ary
            ary = []
          else
            ary << before
          end
        end

        unless ary.nil?
          ary << last_after
          enum.yield ary
        end
      end
    end
  end
end