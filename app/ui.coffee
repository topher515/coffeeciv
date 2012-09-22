context = (window)
Civ = context.Civ or= {}
UI = Civ.UI or= {}
Utils = Civ.Utils or= {}

tplCache = {}


UI.uxDispatcher = _.clone(Backbone.Events)

tpl = (selector)->
  # Return a function which will return a cached version
  # of the template
  (tplCtx)->
    if not tplCache[selector]
      $t = $(selector)
      if $t.length == 0
        throw "Template missing error: #{ id }"
      tplCache[selector] = _.template $t.html()
    tplCache[selector](tplCtx)

UI.Model = Backbone.Model.extend()

UI.View = Backbone.View.extend
  # TODO: Implement: delSubview: (modelOrView)->
  getSubview: (model)->
    return @_subviews?[model.cid]
  removeSubview: (model)->
    subview = @getSubview model
    if subview
      subview.parentView = null
      delete @_subviews[model.cid]
    return subview
  setSubview: (subview)->
    @removeSubview subview.model
    if not @_subviews
      @_subviews = {}
    subview.parentView = @
    return @_subviews[subview.model.cid] = subview
  getSubviews: ->
    return (view for modelCid, view of (@_subviews)) or []
  renderWithSubviews: (inside)->
    if @template
      @$el.html (@template @model?.toJSON())
    # Note that 'inside' will only be a valid selector *after* the 
    # templating has happened
    $elem = if inside then @$(inside) else @$el
    fn = (sv)-> $elem.append sv.render().el
    fn sv for sv in @getSubviews()

  bubble: (obj, evtNames)->
    if not _.isArray evtNames
      evtNames = [evtNames]
    for evtName in evtNames
      obj.on evtName, ((evt)-> @trigger evtName, evt), @

  unbubble: (obj, evtName)->
    obj.off evtName


UI.SelectableView = UI.View.extend
  events:
    "click":"handleSelect"
  handleSelect:->
    @trigger "select:#{ @selectName }", (view:@, name:@selectName)



UI.SingleUnitView = UI.SelectableView.extend
  className:"unit"
  selectName:"unit"
  render:->
    @$el.html('<div class="inner"></div>')
    @


UI.HexView = UI.View.extend
  template: tpl '#hex-tpl'
  className:"hex"


  initialize:(options)->
    @ux = options.ux
    @worldView = options.worldView

    @$el.addClass @model.get 'appearance'
    @$el.attr('id','hex-' + @model.id)
    if @model.get 'isRoot'
      @$el.addClass 'root'

    @worldView.registerHexView @

    @model.on 'unit:create', @handleUnitCreate, @
    @model.on 'city:create', @handleCityCreate, @
    #@model.on 'unit:arrive', @handleUnitArrive, @
    #@model.on 'unit:leave', @handleUnitLeave, @


  handleUnitCreate:(evt)->
    sv = @setSubview (new UI.SingleUnitView model:evt.unit)
    @ux.registerSelectable sv
    @render()

  handleCityCreate:(evt)->
    sv = @setSubview (new UI.CityView model:evt.city)
    @render()

  render:->
    @renderWithSubviews()
    @


UI.HexRowView = UI.View.extend
  className:"hexrow"
  initialize:(options)->
    @rootHex = options.rootHex
    @ux = options.ux
    @worldView = options.worldView

  newHexView: (model)->
    hexView = new UI.HexView (model:model, ux:@ux, worldView:@worldView)
    @bubble hexView, 'unit:create'
    @bubble hexView, 'unit:arrive'
    @bubble hexView, 'unit:leave'
    hexView

  render:->
    # render methodology
    #   r -> (ne se)! -> (nw sw)!
    self = @
    @$el.html ''
    appender = (hex)->
      self.$el.append self.newHexView(hex).render().el
    prepender = (hex)->
      self.$el.prepend self.newHexView(hex).render().el
    @rootHex.applyRight appender, inclusive:true
    @rootHex.applyLeft prepender
    @



UI.HexWorldView = UI.View.extend
  el:'#hexworld'
  initialize:(options)->
    @rootHex = @model.root
    @ux = options.ux
    @hexViewByModel = {}

    # Bubbled up from hexView
    @model.on 'unit:move', @handleUnitMove, @
    _.bindAll @

  registerHexView: (hexView)->
    @hexViewByModel[hexView.model.cid] = hexView

  getHexView:(model)->
    @hexViewByModel[model.cid]

  handleUnitMove: (evt)->
    from = @getHexView(evt.from)
    to = @getHexView(evt.to)
    unitView = from.removeSubview evt.unit
    to.setSubview unitView
    from.render()
    to.render()

  newHexRowView: (model)->
    rowView = new UI.HexRowView (rootHex:model, ux:@ux, worldView:@)
    @bubble rowView, 'unit:create'
    @bubble rowView, 'unit:arrive'
    @bubble rowView, 'unit:leave'
    rowView


  render:->
    # render methodology
    #   r -> s! -> n!
    self = @
    @$el.html('')
    appender = (hex)->
      self.$el.append self.newHexRowView(hex).render().el
    prepender = (hex)->
      self.$el.prepend self.newHexRowView(hex).render().el
    # First render the root hex row and all rows below it
    @rootHex.applyDown appender, inclusive:true
    # Next render all the rows above the root hex
    @rootHex.applyUp prepender
    # Note that this render methodology will miss rendering
    # any hexes that are not directly `n` or `s` of the root node 
    @


UI.CityView = UI.View.extend
  events:
    "click":"handleOpenMetaView"
  className:"city"

  metaTemplate: tpl '#city-meta-tpl'

  handleOpenMetaView:->
    $('#city-meta-modal').html(@metaTemplate @model.toJSON())
        .modal show:true



UI.CityMetaView = UI.View.extend
  el: '#city-meta-modal'
  className:"modal hide fade"


UI.UXController = UI.View.extend
  initialize:(opts)->
    @selectables = []

  handleKeydown:(event)->
    event.keyCode

  registerSelectable:(selectableView)->
    @selectables.push selectableView
    @bubble selectableView, 'select:unit'

  unregisterSelectable:(selectableView)->
    @unbubble selectableView, 'select:unit'


UI.HumanController = UI.View.extend
  el:'#controls'
  events:
    "click .turn-complete":"handleTurnComplete"

  initialize:(opts)->
    @game = opts.game
    @world = opts.world
    @humanPlayer = opts.humanPlayer
    @ux = opts.ux

    @ux.on 'select:unit', @handleSelectUnit, @
    @ux.on 'deselect:unit', @handleDeselectUnit, @

    @game.on 'game:turnComplete', (-> @$('.turn').html( @game.get 'turn' )), @


    @selectedUnitView = null

    _.bindAll @
    @initKeyCommands()

  handleTurnComplete:->
    @humanPlayer.turnComplete()

  move:(dir)->
    @selectedUnitView?.model.move dir

  initKeyCommands:->
    self = @
    Mousetrap.bind "esc", ->
      self.handleDeselectUnit()
    Mousetrap.bind "up", ->
      self.move "n"
    Mousetrap.bind "down", ->
      self.move "s"

    Mousetrap.bind "left up", ->
      self.move "nw"
    Mousetrap.bind "left down", ->
      self.move "sw"

    Mousetrap.bind "right up", ->
      self.move "ne"
    Mousetrap.bind "right down", ->
      self.move "se"

    Mousetrap.bind "b", =>
      @selectedUnitView?.model.buildCity()


  handleSelectUnit:(evt)->
    @selectedUnitView?.$el.removeClass 'selected'
    @selectedUnitView = evt.view
    @selectedUnitView?.$el.addClass 'selected'

  handleDeselectUnit:(evt)->
    @selectedUnitView?.$el.removeClass 'selected'
    @selectedUnitView = null

