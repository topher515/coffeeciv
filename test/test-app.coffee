$ ->
  ctx = window
  ctx.ux = new Civ.UI.UXController

  # Build world
  ctx.world = new Civ.HexWorld (size:40, ux:ux)
  world.buildHexesInGrid()

  # Build world view
  ctx.worldView = new Civ.UI.HexWorldView (model:world, ux:ux)
  worldView.render()

  ctx.civ = new Civ.Civilization (name:"Egyptians")
  ctx.unit = new Civ.SettlerUnit hex:world.root, civ:civ

  ctx.human = new Civ.HumanPlayer civ:civ
  ctx.game = new Civ.Game players:[human]
  new Civ.UI.HumanController humanPlayer:human, ux:ux, game:game

