#
# CoffeeCiv Main
# 

context = (window)
Civ = context.Civ or= {}


class Civ.Hex
  constructor: (world, opts)->
    @world = world
    @id = null
    @altitude = opts.altitude or 0
    @type = opts.type or "grass"

    @n = null
    @ne = null
    @se = null
    @s = null
    @sw = null
    @nw = null

    @world.registerHex(@)

  getNames: ->
    return ['n','ne','se','s','sw','nw']

  getOppositeName: (name)->
    {
      'n': 's',
      'ne':'sw',
      'se':'nw',
      's': 'n',
      'sw':'ne',
      'nw':'se'
    }[name]

  getNeighbors: ->
    return [@n, @ne, @se, @s, @sw, @nw]

  providesFood: -> 2
  providesProd: -> 1
  providesGold: -> 1



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



class HexWorld
  constructor: ()->
    @hexes = {}
    @root = null
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
        newHex = new Hex @
        hex[name] = newHex 
        # Add the new hex to the appropriate ref on this hex
        opName = newHex.getOppositeName(name)
        # Be sure the new hex's reference is set back to this hex
        newHex[opName] = hex 

    for hex in @current.getNeighbors()
      if not @visited[hex.id]
        _buildHexesAround(hex) # 

  buildHexesCircularly: (total)->
    cnt = 0
    @current = @root = new Hex
    while cnt < total




class Civ.City
  
  constructor: (name,opts)->
    @population = opts.popultion or 10

    @health = 1.0
    @supplyOfFood = 0
    @name = name

    @hexset = new HexSet # TODO Figure out what goes here!


  calcGold: -> @hexset.providesGold()
  calcProd: -> @hexset.providesProd()
  calcFood: -> @hexset.providesFood()
  calcScience: -> ##


  tick: ->
    @supplyOfFood += @calculateFood()



# Goverment

class Government
  constructor: (civ)->
    @civ = civ

class Tribal extends Government
  name: "Tribal"

class Monarchy extends Government
  name: "Monarchy"


# Civilization

class Civ.Civilization

  constructor: (player)->
    @player = player
    # Gov
    @government = new Tribal @
    # Sci
    @scienceGraph = new ScienceGraph
    @currentResearch = 
    # Cities
    @cities = []
    @units = []

  getCities: -> @cities
  getUnits: -> @units


  calcScience: ->
    _.reduce @getCities(), (memo,city)-> memo+city.calculateScience(), 0

  tickScience: ->
    sci = @calcScience()
    @scienceGraph.doProgress sci


  tick: ->
    tickScience()



class Civ.Player
  constructor: ->
