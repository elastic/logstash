class String
  # Convenience method for converting strings to UTF-16LE for wide character
  # functions that require it.
  def wincode
    (self.tr(File::SEPARATOR, File::ALT_SEPARATOR) + 0.chr).encode('UTF-16LE')
  end

  # Read a wide character string up until the first double null, and delete
  # any remaining null characters.
  def read_wide
    self[/^.*?(?=\x00{2})/].delete(0.chr)
  end
end
