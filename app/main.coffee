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
    @applyCyclic fn, ['ne','se'], opts

  applyLeft:(fn,opts)->
    @applyCyclic fn, ['nw','sw'], opts

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
    width: 20
    height: 10

  initialize: (options)->
    @hexes = {}
    @root = null
    @count = 0
    @visited = {}
    @hexGrid = {}
    _.bindAll @

  bubble: (obj, evtName)->
    obj.on evtName, ((evt)-> @trigger evtName, evt), @

  registerHex: (hex)->
    hex.id = @count
    @hexes[@count] = hex
    @count += 1

    @bubble hex, 'unit:create'


  _buildHexesAround: (hex)->
    @visited[hex.id] = true # Mark this hex as visited
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


  _buildHexInDir: (current,dir)->
    if current[dir]
      return false
    # Setup neighbor hex
    current[dir] = new Civ.Hex world:@
    # Link neighbor hex to *this* hex
    opDir = current.getOppositeName dir
    current[dir][opDir] = current
    return true

  buildHexesSpirally: ->
    # Given they you've come from 'key'
    # try traveling in 'value' directions (in order)
    # and you should move in a spiral
    spiralOrder = {
      'n':['se','ne','n']
      'ne':['s','se','ne']
      'se':['sw','s','se']
      'sw':['n','nw','sw']
      'nw':['ne','n','nw']
      's':['nw','ne','s']
    }
    current = @root = new Civ.Hex (isRoot:true, world:@)
    cameFrom = 'sw'
    while @count < @get 'size'
      for newDir in spiralOrder[cameFrom]
        built = @_buildHexInDir current, newDir
        if built
          cameFrom = newDir
          current = current[newDir]
          break

  buildHexesInGrid: ->
    hexGrid = @hexGrid
    center = "#{ @get('width') / 2 },#{ @get('height') / 2 }"

    for x in [0..@get 'width']
      for y in [0..@get 'height']
        coord = "#{x},#{y}"
        hexGrid[coord] = new Civ.Hex world:@

    @root = hexGrid["0,0"]

    for x in [0..@get 'width'] by 2
      for y in [0..@get 'height']
        hex = hexGrid["#{x},#{y}"]
        hex.n = hexGrid["#{x},#{y-1}"]
        hex.ne = hexGrid["#{x+1},#{y}"]
        hex.se = hexGrid["#{x+1},#{y+1}"]
        hex.s = hexGrid["#{x},#{y+1}"]
        hex.sw = hexGrid["#{x-1},#{y+1}"]
        hex.nw = hexGrid["#{x-1},#{y}"]

    for x in [1..@get('width') - 1] by 2
      for y in [0..@get 'height']
        hex = hexGrid["#{x},#{y}"]
        hex.n = hexGrid["#{x},#{y-1}"]
        hex.ne = hexGrid["#{x+1},#{y-1}"]
        hex.se = hexGrid["#{x+1},#{y}"]
        hex.s = hexGrid["#{x},#{y+1}"]
        hex.sw = hexGrid["#{x-1},#{y}"]
        hex.nw = hexGrid["#{x-1},#{y-1}"]


Civ.SingleUnit = Backbone.Model.extend
  initialize: (options)->
    @hex = options.hex
    @civ = options.civ

    @hex.trigger 'unit:create', (unit:@, hex:@hex)
    @hex.trigger 'unit:arrive', (unit:@, hex:@hex)

    @civ.registerUnit @


  validMove: (newHex)->
    Boolean newHex

  moveTo: (newHex)->
    if not @validMove newHex
      throw "Invalid Movement Direction"
    oldHex = @hex 
    @hex = newHex
    #@trigger 'unit:move', (to:newHex, from:oldHex, unit:@)
    @hex.world.trigger 'unit:move', (to:newHex, from:oldHex, unit:@)
    oldHex.trigger 'unit:leave', (unit:@, hex:oldHex)
    newHex.trigger 'unit:arrive', (unit:@, hex:newHex )

  move: (dir)->
    @moveTo @hex[dir]

  disband: ->
    @hex.trigger 'unit:leave', {unit:@, hex:@hex}
    @civ.trigger 'unit:disband', {unit:@, civ:@civ, hex:@hex}


Civ.SettlerUnit = Civ.SingleUnit.extend
  
  cost: 25

  buildCity: ->
    new Civ.City {
        name: @civ.player.decideName("Name for city?"), 
        civ:@civ,
        hex:@hex
      }
    @disband()



Civ.City = Backbone.Model.extend

  defaults:
    population: 1.0
    health: 1.0
    supplyOfFood: 0
    name: "Unnamed City"

    progressProd: 0
    currentProd: null

  initialize: (opts)->

    #@hexset = new Civ.HexSet # TODO Figure out what goes here!
    @hex = opts.hex
    @civ = opts.civ
    @hex.trigger 'city:create', {city:@, civ:@civ, hex:@hex}, @
    @civ.trigger 'city:create', {city:@, civ:@civ, hex:@hex}


  calcGold: -> @hexset.providesGold()
  calcProd: -> @hexset.providesProd()
  calcFood: -> @hexset.providesFood()
  calcScience: -> ##


  tick: ->
    @set {
        supplyOfFood: @get('supplyOfFood') + @calcFood()
      }

    # Do Progress calculations
    newProd = @get('progressProd') + @calcProd()
    if newProd >= @currentProd.cost
      new @currentProd {hex:@hex, city:@, civ:@civ}
      @set progressProd: newProd - @currentProd.cost

    else
      @set progressProd: @get('progressProd') + newProd


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
    # Gov
    @government = new Civ.Tribal civ:@
    # Sci
    @scienceGraph = new Civ.ScienceGraph
    @currentResearch = null
    # Cities
    @cities = []
    @units = []

  registerUnit:(unit)->
    @units.push unit
    @trigger 'unit:create', {civ:@,unit:unit,hex:unit.hex}

  registerCity:(city)->
    @cities.push city
    city.on 'unit:create', ((evt)-> @registerUnit(evt.unit)), @

  calcScience: ->
    _.reduce @cities, ((memo,city)-> memo+city.calculateScience()), 0

  tickScience: ->
    sci = @calcScience()
    @scienceGraph.doProgress sci

  tickProd: ->
    for city in @cities
      city.tick()

  tick: ->
    @tickScience()
    @tickProd()



Civ.Player = Backbone.Model.extend
  initialize:(opts)->
    @civ = opts.civ
    @civ.player = @
    @civ.on 'unit:create', @handleUnitCreate

  handleUnitCreate:(evt)->

Civ.HumanPlayer = Civ.Player.extend
  handleUnitCreate:(unit)->
    @trigger 'selectable:registered', unit

  decideName:(promptText)->
    prompt promptText

  turnComplete:->
    @trigger 'player:turnComplete', {player:@}


Civ.ComputerPlayer = Civ.Player.extend()


Civ.Game = Backbone.Model.extend
  defaults:
    turn:1

  initialize:(opts)->
    @players = new (Backbone.Collection.extend(model:Civ.Player))
    @players.reset opts.players
    @currentPlayer = 0
    @players.on 'player:turnComplete', @handlePlayerTurnComplete, @

  handlePlayerTurnComplete:->
    @currentPlayer += 1

    if @currentPlayer == @players.length
      @currentPlayer = 0
      @set turn:(@get 'turn')+1
      @trigger 'game:turnComplete'

    @getCurrentPlayer().civ.tick()


  getCurrentPlayer:->
    @players.at @currentPlayer










