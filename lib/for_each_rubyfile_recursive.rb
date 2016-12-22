def for_each_rubyfile_recursive(root)
  directorylist = %x[find "#{root}" -name '*.rb'].split("\n")
  directorylist.each do |filename|
    yield(filename)
  end
end
