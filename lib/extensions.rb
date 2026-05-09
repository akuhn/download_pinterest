

class Hash
  def method_missing(name, *args)
    fetch(name.to_s) { super }
  end
end

class String
  def to_proc
    string_parts = self.split('.')
    ->(each) { each.dig(*string_parts) }
  end
end

class Binding
  def pry
    require 'pry'
    Pry.start(self)
  end
end
