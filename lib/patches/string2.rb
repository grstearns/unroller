class String
  method_space :code_unroller do

    def make_it_fit(max_width, overflow = :chop_right)
      returning(string = self) do
        if string.length_without_color > max_width      # Wider than desired column width; Needs to be chopped.
          unless max_width < 4                          # Is there even enough room for it if it *is* chopped? If not, then don't even bother.
            #Kernel.p overflow
            if overflow == :chop_left
              #puts "making string (#{string.length_without_color}) fit within #{max_width} by doing a :chop_left"
              #puts "chopping '#{string}' at -(#{max_width} - 3) .. -1!"
              chopped_part = string[-(max_width - 3) .. -1]
              string.replace '...' + chopped_part
            elsif overflow == :chop_right
              #puts "making string (#{string.length_without_color}) fit within #{max_width} by doing a :chop_right"
              chopped_part = string[0 .. (max_width - 3)]
              string.replace chopped_part + '...'
            end
          else
            string = ''
          end
        end
      end
    end

  end
end # class String
