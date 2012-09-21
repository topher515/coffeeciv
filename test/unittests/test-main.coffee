
QUnit.test 'world is valid', (assert)->
  world = new Civ.HexWorld(size:40, ux:null)
  world.buildHexesInGrid()

  root = world.root

  assert.equal(root.n.id, root.ne.nw.id)
  assert.equal(root.n.id, root.nw.ne.id)

  assert.equal(root.ne.id, root.n.se.id)
  assert.equal(root.ne.id, root.se.n.id)

  assert.equal(root.se.id, root.ne.s.id)
  assert.equal(root.se.id, root.s.ne.id)

  assert.equal(root.s.id, root.se.sw.id)
  assert.equal(root.s.id, root.sw.se.id)

  assert.equal(root.sw.id, root.s.nw.id)
  assert.equal(root.sw.id, root.nw.s.id)

  assert.equal(root.nw.id, root.sw.n.id)
  assert.equal(root.nw.id, root.n.sw.id)