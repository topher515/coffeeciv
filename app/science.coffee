#
# CoffeeCiv Science
#
context = (window)
Civ = context.Civ or= {}
UI = Civ.UI or= {}
Utils = Civ.Utils or= {}

class Civ.Discovery
  constructor: ->
    # TODO: Calculate dependency graph
    @progress = 0
  getRemaining: ->
    @cost - @progress
  getDisables: ->
    @disables
  getEnables: ->
    @enables

Discoveries = Civ.Discoveries = {}

class Discoveries.Bliss extends Civ.Discovery
  name:"Ignorance"
  id:"bliss"
  enables:["pottery"]
  cost:0.0

class Discoveries.Feudalism extends Civ.Discovery
  name:"Feudalism"
  id:'feud'
  enables: []
  cost:20.0

class Discoveries.Pottery extends Civ.Discovery
  name:"Pottery"
  id:'pot'
  enables: []
  cost:5.0



class Civ.ScienceGraph
  constructor: (civ)->
    @civ = civ
    @root = new Discoveries.Bliss
    @current = null
    @last = @root

  doProgress: (pts)->
    if @current.getRemaining() > pts
      @current.progress += pts
      return

    remainder = pts - @current.getRemaining()

    @current = @civ.player.decideNextScience()
    @doProgress()


