// Generated by CoffeeScript 1.3.3
(function() {

  $(function() {
    var ctx;
    ctx = window;
    ctx.world = new Civ.HexWorld({
      size: 40
    });
    world.buildHexesCircularly();
    ctx.worldView = new Civ.UI.HexWorldView({
      rootHex: world.root
    });
    return worldView.render();
  });

}).call(this);
