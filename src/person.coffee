class Person
  constructor: (@name) -> @
  say: ->
    return "My name is #{@name}"

exports?.Person = Person


