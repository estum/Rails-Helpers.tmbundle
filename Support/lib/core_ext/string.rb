class String  
  def without (str)
    split(str).join
  end
  
  def without! (str)
    self.sub! self.dup, without(str)
  end
  
  def in? (arr)
    arr.include?(self)
  end
  
  alias - :without
end