def tabelize(aa)
  format = '%-20s' * aa[0].length
  aa.each do |a|
    puts format % a
  end
end
