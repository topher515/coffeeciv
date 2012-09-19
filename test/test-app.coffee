$ ->
  ctx = window
  ctx.ux = new Civ.UI.UXController

  # Build world
  ctx.world = new Civ.HexWorld (size:40, ux:ux)
  world.buildHexesCircularly()

  ctx.human = new Civ.HumanPlayer 
  new Civ.UI.HumanController humanPlayer:human, ux:ux

  # Build world view
  ctx.worldView = new Civ.UI.HexWorldView (model:world, ux:ux)
  worldView.render()

  ctx.civ = new Civ.Civilization (name:"Egyptians", player:human)
  ctx.unit = new Civ.SingleUnit hex:world.root, civ:civ
