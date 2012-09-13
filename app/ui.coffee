context = (window)
Civ = context.Civ or= {}
UI = Civ.UI or= {}
Utils = Civ.Utils or= {}

tplCache = {}

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



UI.HexView = UI.View.extend
  template: tpl '#hex-tpl'
  className:"hex"
  initialize:(options)->
    @$el.addClass @model.get 'appearance'
    @$el.attr('id','hex-' + @model.id)
    
  render:->
    @$el.html (@template @model.toJSON())
    @


UI.HexRowView = UI.View.extend
  className:"hexrow"
  initialize:(options)->
    @rootHex = options.rootHex

  newHexView: (model)->
    new UI.HexView model:model

  render:->
    # render methodology
    #   r -> (ne se)! -> (nw sw)!
    self = @
    @$el.html('')
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
    @rootHex = options.rootHex

  newHexRowView: (model)->
    new UI.HexRowView rootHex:@rootHex

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







