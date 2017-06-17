class Crinja::Operator
  class Minus < Binary
    name "-"

    def value(env : Environment, op1, op2)
      if op1.number? && op2.number?
        op1.as_number - op2.as_number
      else
        raise Callable::ArgumentError.new(self, "Both operators need to be numeric")
      end
    end
  end
end
