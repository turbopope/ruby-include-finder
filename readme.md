# Fuzzy Ruby Method Finder

Finds the source files of methods called in a ruby file.



## Drawbacks

This is an imperfect and heuristic approach because Ruby makes static analysis very hard but I really do not want to do dynamic analysis. The heuristic should be fine in most cases, but here are some corner cases and reasons where and why it could fail:


### Duck Typing

This is a heuristic approach since Ruby is [Duck Typed](https://en.wikipedia.org/wiki/Duck_typing) and that makes it impossible (I think?) to infer the type of a variable through static analysis (without executing the code). Take this code for example ([simplified version from the wikipedia article](https://en.wikipedia.org/wiki/Duck_typing#In_Ruby)):

```Ruby
class Duck
  def quack
    puts "Quaaaaaack!"
  end
end

class Person
  def quack
    puts "The person imitates a duck."
  end
end

def in_the_forest(duck)
  duck.quack
end

donald = Duck.new
john = Person.new
in_the_forest john # => "Quaaaaaack!"
in_the_forest donald # => "The person imitates a duck."
```

A static analysis (at least a simple one) will see that `quack` is called on the local variable `duck`. Due to concept of Duck Typing, `duck` is actually neither a `Duck`- not a `Person`-Object. It merely responds to the method `quack` in both cases. In fact, if we were to pass a variable that was not created from a class that implements `duck`/does not respond to `quack`, this would not cause a compile error, just a runtime error. So, without executing the code, we cannot know the type of the local variable `duck`.

Here is another example:

```Ruby
if rand(2) == 0
  def foo
    puts "a"
  end
else
  def foo
    puts "b"
  end
end

foo # => "a" or "b"
```

In this case, the situation is even worse, since it is not even (theoretically) deterministic which version of `foo` will be defined.


### Wrapping and Aliasing

Consider the case of [Faraday's main file](https://github.com/lostisland/faraday/blob/e66210bd9dca6ad4628d880a038381baa0bccf0b/lib/faraday.rb)

```Ruby
def require_libs(*libs)
  libs.each do |lib|
    require "#{lib_path}/#{lib}"
  end
end
# ...
require_libs "utils", "options", "connection", "rack_builder", "parameters", "middleware", "adapter", "request", "response", "upload_io", "error"
```

Funny. They wrap the kernel `require` into a custom method and use that to require files instead. While we could hard-code a solution for this specific case, in general we are unable to trace wrappers like this one back to the actual include without interpreting the code.

The same is true for aliasing the kernel `require` as in:

```Ruby
alias require grab_lib
grab_lib 'json'
```
