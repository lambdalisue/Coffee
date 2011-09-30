vows      = require 'vows'
assert    = require 'assert'
{Person}  = require '../src/person'

vows.describe('Person').addBatch
  'A instance':
    topic: new Person 'Mike'
    'has name': (person) ->
      assert.equal person.name, 'Mike'
    'say name': (person) ->
      assert.equal person.say(), 'My name is Mike'
.export module
