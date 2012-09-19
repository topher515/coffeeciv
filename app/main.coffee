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
Civ.Hex = Backbone.Model.extend # TODO: Convert this back into coffeescript style inheritance
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
    isRoot:false


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

  registerUnit:(unit)->
    @trigger 'unit:create', (unit:unit, hex:@)
    @trigger 'unit:arrive', (unit:unit, hex:@)

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



Civ.HexWorld = Backbone.Model.extend
  defaults:
    size: 100

  initialize: (options)->
    @hexes = {}
    @root = null
    @count = 0
    @visited = {}
    _.bindAll @

  bubble: (obj, evtName)->
    obj.on evtName, ((evt)-> @trigger evtName, evt), @

  registerHex: (hex)->
    hex.id = @count
    @hexes[@count] = hex
    @count += 1

    @bubble hex, 'unit:create'


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
        if @count >= @get 'size'
          return # TODO: Maybe I should throw something here?

    for hex in @current.getNeighbors()
      if not @visited[hex.id]
        @_buildHexesAround(hex) # 

  buildHexesCircularly: ()->
    cnt = 0
    @current = @root = new Civ.Hex (isRoot:true, world:@)
    @_buildHexesAround @root



Civ.SingleUnit = Backbone.Model.extend
  initialize: (options)->
    @hex = options.hex
    @civ = options.civ
    @hex.registerUnit @
    @civ.registerUnit @


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

Civ.Government = Backbone.Model.extend
  initialize: (opts)->
    @civ = opts.civ

Civ.Tribal = Civ.Government.extend
  name: "Tribal"

Civ.Monarchy = Civ.Government.extend
  name: "Monarchy"


# Civilization

Civ.Civilization = Backbone.Model.extend
  defaults:
    name: "Unnamed"

  initialize: (attrs)->
    @player = attrs.player
    # Gov
    @government = new Civ.Tribal civ:@
    # Sci
    @scienceGraph = new Civ.ScienceGraph
    @currentResearch = null
    # Cities
    @cities = []
    @units = []

  registerUnit: (unit)->
    @player.registerUnit unit
    @units.push unit

  getCities: -> @cities
  getUnits: -> @units


  calcScience: ->
    _.reduce @getCities(), ((memo,city)-> memo+city.calculateScience()), 0

  tickScience: ->
    sci = @calcScience()
    @scienceGraph.doProgress sci


  tick: ->
    tickScience()



Civ.Player = Backbone.Model.extend
  initialize:(opts)->

Civ.HumanPlayer = Civ.Player.extend
  registerUnit:(unit)->
    @trigger 'selectable:registered', unit

  
