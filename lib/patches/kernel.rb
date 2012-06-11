
# Make it really, really easy and concise, for those who like it that way.
module Kernel
  def tron(*args)
    Unroller::trace_on(*args)
  end
  def troff(*args)
    Unroller::trace_off(*args)
  end
end
