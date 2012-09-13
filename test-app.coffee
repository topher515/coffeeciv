$ ->
  ctx = window
  ctx.world = new Civ.HexWorld size:40
  world.buildHexesCircularly()

  ctx.unit = new Civ.SingleUnit hex:world.root

  ctx.worldView = new Civ.UI.HexWorldView rootHex:world.root
  worldView.render()

