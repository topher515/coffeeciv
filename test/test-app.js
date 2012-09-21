// Generated by CoffeeScript 1.3.3
(function() {

  $(function() {
    var ctx;
    ctx = window;
    ctx.ux = new Civ.UI.UXController;
    ctx.world = new Civ.HexWorld({
      size: 40,
      ux: ux
    });
    world.buildHexesInGrid();
    ctx.human = new Civ.HumanPlayer;
    new Civ.UI.HumanController({
      humanPlayer: human,
      ux: ux
    });
    ctx.worldView = new Civ.UI.HexWorldView({
      model: world,
      ux: ux
    });
    worldView.render();
    ctx.civ = new Civ.Civilization({
      name: "Egyptians",
      player: human
    });
    return ctx.unit = new Civ.SingleUnit({
      hex: world.root,
      civ: civ
    });
  });

}).call(this);
