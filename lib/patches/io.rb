class IO
  # Gets a single character, as a string.
  # Adjusts for the different behavior of getc if we are using termios to get it to return immediately when you press a single key
  # or if they are not using that behavior and thus have to press Enter after their single key.
  def getch
    response = getc
    if !$termios_loaded
      next_char = getc
      new_line_characters_expected = ["\n"]
      #new_line_characters_expected = ["\n", "\r"] if windows?
      if next_char.chr.in?(new_line_characters_expected)
        # Eat the newline character
      else
        # Don't eat it
        # (This case is necessary, for escape sequences, for example, where they press only one key, but it produces multiple characters.)
        $stdin.ungetc(next_char)
      end
    end
    response.chr
  end
end