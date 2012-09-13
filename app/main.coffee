#
# CoffeeCiv Main
# 
context = (window)
Civ = context.Civ or= {}
UI = Civ.UI or= {}
Utils = Civ.Utils or= {}


class Utils.Cycler
  constructor:(items)->
    @items = items
    @ptr = 0
    _.bindAll @
  next:->
    item = @items[@ptr]
    @ptr = if @ptr+1 < @items.length then @ptr+1 else 0
    return item


#class Civ.Hex extends Backbone.Model
Civ.Hex = Backbone.Model.extend # TODO: Convert this back into coffeescript inheritance
  defaults:
    appearance:'grass'
    movementCosts:
      land:1.0
      air:1.0
      sea:Infinity
    defence:1.0
    attack:1.0
    food:1.0
    gold:1.0
    prod:1.0


  #constructor: (world, opts)->
  initialize: (opts)->
    @world = opts.world # world
    #@id = null

    @n = null
    @ne = null
    @se = null
    @s = null
    @sw = null
    @nw = null

    @world.registerHex @
    _.bindAll @



  getNames: ->
    return ['n','ne','se','s','sw','nw']

  getOppositeName: (name)->
    {
      'nw':'se',
      'ne':'sw',
      'n' :'s',
      'se':'nw',
      'sw':'se',
      's' :'n'
    }[name]

  getNeighbors: ->
    self = @
    _.map @getNames(), (name)-> self[name]

  providesFood: -> 2
  providesProd: -> 1
  providesGold: -> 1

  toJSON: ->
    self = @
    json = Backbone.Model::toJSON.call @
    _.each @getNames(), (name)-> json[name] = self[name]?.id
    json

  applyCyclic:(fn,cycle,opts)->
    curHex = @
    if opts?.inclusive
      # func(currentHex, previousHex, nameToHere)
      fn curHex, null, null

    cycler = new Utils.Cycler(cycle or [])

    next = cycler.next()
    while curHex[next]
      fn curHex[next], curHex, next
      curHex = curHex[next]
      next = cycler.next()

  applyRight:(fn,opts)->
    @applyCyclic fn, ['nw','sw'], opts

  applyLeft:(fn,opts)->
    @applyCyclic fn, ['ne','se'], opts

  applyUp:(fn,opts)->
    @applyCyclic fn, ['n'], opts

  applyDown:(fn,opts)->
    @applyCyclic fn, ['s'], opts


# Cities

class Civ.HexSet

  getHexes: ->
    []

  apply: (fn)->
    _.each @getHexes(), fn

  providesGold: ->
    _.reduce @getHexes(), ((memo,hex)->
        memo + hex.providesGold() 
      ), 0

  providesProd: ->
    _.reduce @getHexes(), ((memo,hex)->
        memo + hex.providesProd() 
      ), 0

  providesFood: ->
    _.reduce @getHexes(), ((memo,hex)->
        memo + hex.providesFood() 
      ), 0



class Civ.HexWorld
  constructor: (options)->
    @hexes = {}
    @root = null
    @size = options.size or 100
    @count = 0

    @visited = {}

  registerHex: (hex)->
    hex.id = @count
    @hexes[@count] = hex
    @count += 1


  _buildHexesAround: (hex)->
    @visited[hex.id] = true # Mark this hax as visited
    for name in hex.getNames()
      if not hex[name]
        newHex = new Civ.Hex world:@
        hex[name] = newHex 
        # Add the new hex to the appropriate ref on this hex
        opName = newHex.getOppositeName(name)
        # Be sure the new hex's reference is set back to this hex
        newHex[opName] = hex 
        if @count >= @size
          return # TODO: Maybe I should throw something here?

    for hex in @current.getNeighbors()
      if not @visited[hex.id]
        @_buildHexesAround(hex) # 

  buildHexesCircularly: ()->
    cnt = 0
    @current = @root = new Civ.Hex world:@
    @_buildHexesAround @root



Civ.SingleUnit = Backbone.Model.extend
  initialize: (attrs,options)->
    @hex = options.hex

  validMove: (newHex)->
    Boolean newHex

  moveTo: (newHex)->
    if not @validMove newHex
      throw "Invalid Movement Direction"
    oldHex = @hex 
    @hex = newHex
    @trigger 'unit:move', (to:newHex, from:oldHex, unit:@)
    oldHex.trigger 'unit:leave', (unit:@, hex:oldHex)
    newHex.trigger 'unit:arrive', (unit:@, hex:newHex )

  move: (dir)->
    moveTo @hex[dir]



class Civ.City
  
  constructor: (name,opts)->
    @population = opts.popultion or 10

    @health = 1.0
    @supplyOfFood = 0
    @name = name

    @hexset = new Civ.HexSet # TODO Figure out what goes here!


  calcGold: -> @hexset.providesGold()
  calcProd: -> @hexset.providesProd()
  calcFood: -> @hexset.providesFood()
  calcScience: -> ##


  tick: ->
    @supplyOfFood += @calculateFood()



# Goverment

class Civ.Government
  constructor: (civ)->
    @civ = civ

class Tribal extends Civ.Government
  name: "Tribal"

class Monarchy extends Civ.Government
  name: "Monarchy"


# Civilization

class Civ.Civilization

  constructor: (player)->
    @player = player
    # Gov
    @government = new Civ.Tribal @
    # Sci
    @scienceGraph = new Civ.ScienceGraph
    @currentResearch = 
    # Cities
    @cities = []
    @units = []

  getCities: -> @cities
  getUnits: -> @units


  calcScience: ->
    _.reduce @getCities(), ((memo,city)-> memo+city.calculateScience()), 0

  tickScience: ->
    sci = @calcScience()
    @scienceGraph.doProgress sci


  tick: ->
    tickScience()



class Civ.Player
  constructor: ->
