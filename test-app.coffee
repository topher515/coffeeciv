$ ->
  ctx = window
  ctx.world = new Civ.HexWorld size:40
  world.buildHexesCircularly()

  ctx.worldView = new Civ.UI.HexWorldView rootHex:world.root
  worldView.render()