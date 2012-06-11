require_relative 'unroller'


#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#
# :todo: These tests seriously need to be converted into automated tests. But I was lazy/in a hurry when I wrote this...
# It would be kind of cool if we could simultaneously *capture* the output (for asserting things against in automated tests) and
# *display* the output (so that we can manually check for *visual*/stylistic/color regression problems that automated tests 
# couldn't really judge ... and because it's just pretty to look at :) ).

if $0 == __FILE__
  require 'test/unit'

  def herald(message)
    puts message.ljust(130).bold.white.on_magenta
  end

  Unroller::display_style = :concise #:show_entire_method_body

  class TheTest < Test::Unit::TestCase
    def test_1
    end
  end


  herald '-----------------------------------------------------------'
  herald 'Can call trace_off even if not tracing'
  herald '(Should see no output)'
  Unroller::trace_off

  herald '-----------------------------------------------------------'
  herald 'Can call exclude even if not tracing'
  herald '(Should see no output)'
  Unroller::exclude

  herald '-----------------------------------------------------------'
  herald 'Testing return value (should print 3 in this case)'
  puts Unroller::trace { 1 + 2 }

  herald '-----------------------------------------------------------'
  herald 'Simple test'

# debugger

  def jump!(how_high = 3)
    how_high.times do
      'jump!'
    end
  end
  Unroller::trace
  jump!(2)
  Unroller::trace_off

  herald '-----------------------------------------------------------'
  herald "Testing that this doesn't trace anything (condition == false proc)"
  $trace = false
  Unroller::trace(:condition => proc { $trace }) do
    jump!
  end

  herald '-----------------------------------------------------------'
  herald "Testing that this doesn't trace the inner method (method2), but does trace method1 and method3 (exclude)"
  def method1; end
  def method2
    'stuff!'
  end
  def method3; end
  Unroller::trace do
    method1
    Unroller::exclude do
      method2
    end
    method3
  end

  herald '-----------------------------------------------------------'
  herald "Testing that we can try to turn tracing on even if it's already on"
  def method1
    Unroller::trace
    v = 'in method1'
  end
  Unroller::trace do
    Unroller::trace do
      v = 'about to call method1'
      method1
    end
    v = "We've exited out of one trace block, but we're still within a trace block, so this line should be traced."
  end


  herald '-----------------------------------------------------------'
  herald 'Test with block; very deep (test for over-wide columns)'
  ('a'..last='y').each do |method_name|
    next_method_name = method_name.next unless method_name == last
    eval <<-End, binding, __FILE__, __LINE__ + 1
      def _#{method_name}
        #{next_method_name && "_#{next_method_name}"}
      end
    End
  end
  Unroller::trace(:depth => 5) do
    _a
  end

  herald '-----------------------------------------------------------'
  herald 'Test watching a call stack unwind (only)'
  ('a'..last='y').each do |method_name|
    next_method_name = method_name.next unless method_name == last
    eval <<-End, binding, __FILE__, __LINE__ + 1
      def _#{method_name}
        #{next_method_name && "_#{next_method_name}"}
        #{'Unroller::trace(:depth => caller(0).size)' if method_name == last }
      end
    End
  end
  _a
  Unroller::trace_off


  herald '-----------------------------------------------------------'
  herald 'Testing :depth => :use_call_stack_depth'
  def go_to_depth_and_call_1(depth, &block)
    #puts caller(0).size
    if caller(0).size == depth
      puts 'calling a'
      block.call
    else
      go_to_depth_and_call_2(depth, &block)
    end
    #puts caller(0).size
  end
  def go_to_depth_and_call_2(depth, &block)
    #puts caller(0).size
    if caller(0).size == depth
      puts 'calling a'
      block.call
    else
      go_to_depth_and_call_1(depth, &block)
    end
    #puts caller(0).size
  end
  ('a'..last='c').each do |method_name|
    next_method_name = method_name.next unless method_name == last
    eval <<-End, binding, __FILE__, __LINE__ + 1
      def _#{method_name}
        #{next_method_name && "_#{next_method_name}"}
      end
    End
  end
  go_to_depth_and_call_1(14) do
    Unroller::trace(:depth => :use_call_stack_depth) do
      _a
    end
  end

  herald '-----------------------------------------------------------'
  herald 'Testing without :depth => :use_call_stack_depth (for comparison)'
  go_to_depth_and_call_1(14) do
    Unroller::trace() do
      _a
    end
  end

  herald '-----------------------------------------------------------'
  herald "Test max_depth 5: We shouldn't see the calls to f, g, ... because their depth > 5"
  ('a'..last='y').each do |method_name|
    next_method_name = method_name.next unless method_name == last
    eval <<-End, binding, __FILE__, __LINE__ + 1
      def _#{method_name}
        #{next_method_name && "_#{next_method_name}"}
      end
    End
  end
  Unroller::trace(:max_depth => 5) do
    _a
  end

  herald '-----------------------------------------------------------'
  herald 'Test with long filename (make sure it chops it correctly)'
  File.open(filename = '_code_unroller_test_with_really_really_really_really_really_really_really_really_really_long_filename.rb', 'w') do |file|
    file.puts "
      def sit!
        jump!
      end
    "
  end
  load filename
  Unroller::trace(:depth => 5) do
    sit!
  end
  require 'fileutils'
  FileUtils.rm filename

  herald '-----------------------------------------------------------'
  herald 'Test @max_lines'
  ('a'..last='h').each do |method_name|
    next_method_name = method_name.next unless method_name == last
    eval <<-End, binding, __FILE__, __LINE__ + 1
      def _#{method_name}
        #{next_method_name && "_#{next_method_name}"}
      end
    End
  end
  Unroller::trace(:max_lines => 20) do
    _a
  end

  herald '-----------------------------------------------------------'
  herald 'Test :line_matches'
  herald 'Should only see lines matching "$a_global"'
  require 'facets/string/to_re'
  Unroller::trace :line_matches => '$a_global'.to_re do
    # This won't print anything, because for evals that are missing the __FILE__, __LINE__ arguments, we can't even read the source code (unfortunately)
    eval %(
    whatever = 'whatever'
    $a_global = '1st time'
    foo = 'foo'
    $a_global = '2nd time'
    blah = 'blah'
    )

    # This should print 2 lines:
    whatever = 'whatever'
    $a_global = '1st time'
    foo = 'foo'
    $a_global = '2nd time'
    blah = 'blah'
  end

  herald '-----------------------------------------------------------'
  herald 'Test :file_match'
  herald 'Should only see calls to in_this_file'
  require_local '../test/other_file'
  def in_this_file
    a = 'a'
    b = 'b'
    c = 'c'
    etc = 'etc.'
  end
  Unroller::trace(:file_match => __FILE__) do
    in_this_file()
    in_other_file()
  end

  herald '-----------------------------------------------------------'
  herald 'Test :dir_match'
  herald 'Should only see calls to in_this_file'
  Unroller::trace(:dir_match => __FILE__) do
    in_this_file()
    in_other_file()
  end

  herald '-----------------------------------------------------------'
  herald 'Test @exclude_methods'
  herald 'Should only see calls to green, strong'
  class Wasabi #:nodoc:
    def green
      '...'
    end
    def too_green
      '...'
    end
    def strong
      '...'
    end
    def too_strong
      '...'
    end
  end
  wasabi = Wasabi.new
  Unroller::trace(:exclude_methods => /too_/) do
    wasabi.green
    wasabi.too_green    # Censored, sucka!
    wasabi.strong
    wasabi.too_strong   # Censored, sucka!
  end

  herald '-----------------------------------------------------------'
  herald 'Test @exclude_methods with symbol'
  herald "Should should see too_strong, because that doesn't exactly match the exclusion regexp"
  Unroller::trace(:exclude_methods => :too_) do
    wasabi.too_strong
  end

  herald '-----------------------------------------------------------'
  herald 'Test @exclude_classes'
  herald 'Should only see calls to Interesting::...'
  class Interesting #:nodoc:
    def self.method
      '...'
    end
    def method
      '...'
    end
  
  end
  module Uninteresting #:nodoc:
  
    class ClassThatCluttersUpOnesTraces #:nodoc:
      ('a'..last='h').each do |method_name|
        next_method_name = method_name.next unless method_name == last
        eval <<-End, binding, __FILE__, __LINE__ + 1
          def _#{method_name}
            #{next_method_name && "_#{next_method_name}"}
            #{'Interesting::method' if method_name == last }
            #{'Interesting.new.method' if method_name == last }
          end
        End
      end
    end
  end
  def create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces
    Uninteresting::ClassThatCluttersUpOnesTraces.new._a
  end
  Unroller::trace(:exclude_classes => Uninteresting::ClassThatCluttersUpOnesTraces) do
    create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces
  end

=begin HistoricalNote
    # This test used to generate output more like this (note the extreme indenting):

     |    create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces  | unroller.rb:645
     |  + calling Object::create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces
     |  / def create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces  | unroller.rb:641
     |  |    Uninteresting::ClassThatCluttersUpOnesTraces.new.a             | unroller.rb:642
     |  |  |  |  |  |  |  |  |  |  + calling Interesting::method
     |  |  |  |  |  |  |  |  |  |  / def self.method                        | unroller.rb:620
     |  |  |  |  |  |  |  |  |  |  |    '...'                               | unroller.rb:621
     |  |  |  |  |  |  |  |  |  |  \ end (returning from Interesting::method)  | unroller.rb:622
     |  |  |  |  |  |  |  |  |  |  + calling Interesting::method
     |  |  |  |  |  |  |  |  |  |  / def method                             | unroller.rb:623
     |  |  |  |  |  |  |  |  |  |  |    '...'                               | unroller.rb:624
     |  |  |  |  |  |  |  |  |  |  \ end (returning from Interesting::method)  | unroller.rb:625
     |  \ end (returning from )    

    # ... which is probably a technically more accurate picture of the current call stack. However, it looked kind of unnatural
    # with all those "extra" indents in there. It was also a waste of horizontal screen space.

    # This changed when the idea of an @internal_depth separate from the @depth (that the user sees) was introduced.

     |    create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces  | unroller.rb:655
     |  + calling Object::create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces
     |  / def create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces  | unroller.rb:651
     |  |    Uninteresting::ClassThatCluttersUpOnesTraces.new.a             | unroller.rb:652
     |  |  + calling Interesting::method
     |  |  / def self.method                                                | unroller.rb:630
     |  |  |    '...'                                                       | unroller.rb:631
     |  |  \ end (returning from Interesting::method)                       | unroller.rb:632
     |  |  + calling Interesting::method
     |  |  / def method                                                     | unroller.rb:633
     |  |  |    '...'                                                       | unroller.rb:634
     |  |  \ end (returning from Interesting::method)                       | unroller.rb:635
     |  \ end (returning from Object::create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces)  | unroller.rb:653

    Much cleaner looking...
=end

  herald '-----------------------------------------------------------'
  herald 'Now let\'s be recursive! We should *not* see any calls to Interesting::* this time. But after we return from it, we should see the call to jump!'
  Unroller::trace(:exclude_classes => [Unroller::ClassExclusion.new('Uninteresting', :recursive)]) do
    create_an_instance_of_UninterestingClassThatCluttersUpOnesTraces
    jump!
  end


  herald '-----------------------------------------------------------'
  herald 'Test class definition'
  Unroller::trace do
    class NewClass #:nodoc:
      def hi
        'hi'
      end
    end
  end


  herald '-----------------------------------------------------------'
  herald 'Test rescuing exception'
  def raise_an_error
    raise 'an error'
  end
  Unroller::trace do
    raise_an_error
  end rescue nil

  herald '-----------------------------------------------------------'
  herald 'Demonstrate how :if condition is useful for local variables too (especially loops and iterators)'
  (1..6).each do |i|
    Unroller::trace :if => proc { 
      if (3..4).include?(i)
        puts "Yep, it's a 3 or a 4. I guess we'll enable the tracer for this iteration then...:"
        true
      end 
    } do
      puts "i is now equal to #{i}"
    end
  end

  herald '-----------------------------------------------------------'
  herald 'Testing the :rails "preset"'
  module ActiveSupport #:nodoc:
    def self.whatever
      'whatever'
    end
  end
  module ActiveMongoose #:nodoc:
    def self.whatever
      'whatever'
    end
  end
  Unroller::trace :preset => :rails do
    ActiveSupport.whatever
    ActiveMongoose.whatever
    ActiveSupport.whatever
  end

  herald '-----------------------------------------------------------'
  herald 'Testing the :dependencies "preset"'
  module ActiveSupport #:nodoc:
    module Dependencies #:nodoc:
      def self.whatever
        'whatever'
      end
    end
  end
  module Gem #:nodoc:
    def self.whatever
      'whatever'
    end
  end
  Unroller::trace :preset => :dependencies do
    ActiveSupport::Dependencies.whatever
    Gem.whatever
  end

  herald '-----------------------------------------------------------'
  herald 'Testing showing local variables'
  def sum(a, b, c)
    a + b + c
  end
  def my_very_own_method
    Unroller::trace :show_args => false, :show_locals => true do
      sum = sum(1, 2, 3)
      sum
      sum = sum(3, 3, 3)
    end
  end
  my_very_own_method

  herald '-----------------------------------------------------------'
  herald 'Testing watch_for_added_methods'
  class Foo #:nodoc:
    def existing_method; end
  end
  Unroller::watch_for_added_methods(Foo, /interesting/) do
    class Foo #:nodoc:
      def foo; end
      def an_interesting_method; end
    end
  end

  herald '-----------------------------------------------------------'
  herald 'Testing :display_style => :show_entire_method_body'
  def bagel
    '...'
  end
  Unroller::trace :display_style => :show_entire_method_body do
    bagel
  end

  herald '-----------------------------------------------------------'
  herald 'Testing :show_filename_and_line_numbers => false'
  'foo'; def bagel
    '...'
  end
  Unroller::trace :display_style => :show_entire_method_body, :show_filename_and_line_numbers => false do
    bagel
  end

  herald '-----------------------------------------------------------'
  herald 'Testing that it finds the definition block even when we use define_method instead of the normal def'
  (class << self; self; end).send :define_method, :big_ol_gaggle do
    '...'
  end
  Unroller::trace :display_style => :show_entire_method_body do
    big_ol_gaggle
  end

#  herald '-----------------------------------------------------------'
#  herald 'Testing :interactive => true / interactive debugger'
#  def factorial(x)
#    if x == 1
#      x
#    else
#      x * factorial(x - 1)
#    end
#  end
#  Unroller::debug do
#    factorial(4)
#  end

  herald '-----------------------------------------------------------'
  herald 'Testing :interactive => true / interactive debugger: two calls on the same line'
  def method_1
    'stuff'
  end
  def method_2
    'stuff'
  end
  # Step Over will step over the call to method_1 but will immediately step into method_2, without coming back to this line to ask you what you want to do about the call to method_2 ...
  # In other words, there is no intermediate 'line' event between the 2 'call' events (right?)
  # This could be confusing to some users... Should we hack it to somehow detect that there are two calls in a row for the same 
  # line and artificially inject a pseudo-line event in between so that we have a chance to show the menu again??
  Unroller::debug do
    sum = method_1 + method_2
    puts sum
  end

  herald '-----------------------------------------------------------'
  herald 'Testing :interactive => true / interactive debugger: with blocks'
  def block_taker(&block)
    puts "I'm the block taker. I take blocks."
    puts "Please Step Over the next line."
    yield   # buggy! it keeps stopping at every line in the yielded block, but shouldn't. 
    # false:: (unroller.rb:1433) (line): ??
    puts "Done yielding to the block"
  end
  Unroller::debug do
    puts "If you do a Step Over, will it go into the block or not? Nope. Because we skipped tracing the yield."
    # to do: have a separate "step over method body but into block" option??
    # that way, it you just want to stay in this local file and avoid seeing the code that *wraps* the call to the block, you could do so...
    block_taker do
      puts 'Pick me! Pick me!'
      puts 'I say! When will I ever be executed?'
      puts 'Oh dear, will they just skip right over me?'
      puts 'Or will they Step In here and take a look?'
    end
  end

  herald '-----------------------------------------------------------'
  herald 'Testing :interactive => true / interactive debugger'
  def subway
    question = 'What kind of bread would you like?'
    bread!
    question = 'Would you like any cheese?'
    cheese!
    question = 'Would you like pickles on that?'
    pickles!
  end
  def bread!
    _do = nil
    _do = nil
    _do = nil
  end
  def cheese!
    _do = nil
    _do = nil
    _do = nil
  end
  def pickles!
    _do = nil
    _do = nil
    _do = nil
  end
  #Unroller::trace :display_style => :show_entire_method_body, :interactive => true do
  Unroller::debug do
    subway
  end

  herald 'End of non-automated tests'
  herald '-----------------------------------------------------------'

end # if $0 == __FILE__ (Tests)

# Set terminal_attributes back to how we found them...
# (This doesn't work so great when you do tracing from within a test... Why not? Because Test::Unit is itself *started* using
# an at_exit callback. Which means (since those callbacks are called in reverse order) that *this* at_exit is called, and *then*
# the test's at_exit is called... So in other words, we end up 'reverting' these attributes before we've even had a chance to
# use the 'new' attributes!)
#at_exit { puts 'Setting terminal_attributes back to how we found them...'; Termios.tcsetattr(STDIN, 0, save_terminal_attributes) }
