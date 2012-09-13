#! env node
connect = require 'connect'
connect.createServer(connect.static __dirname).listen 9191
console.log("Started static server on 9191")