
fs = require 'fs'
level = require 'level'
minimist = require 'minimist'
parseUrl = require('url').parse
path = require 'path'
querystring = require 'querystring'
untildify = require 'untildify'
{Server} = require 'http'

transparentGif = new Buffer [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00
  0x00, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b
]

idPattern = /^[a-z0-9_]+$/i

main = (argv) ->
  opts = minimist argv,
    default:
      port: 5000
      databasePath: '~/.snoopdog_db'

  dbPath = untildify opts.databasePath

  try
    fs.mkdirSync dbPath
  catch error
    throw error unless error.code is 'EEXIST'

  db = level dbPath, {valueEncoding: 'json'}

  getSession = (id, callback) ->
    db.get id, (error, result) ->
      if error?.name is 'NotFoundError'
        error = null
        result = {id, hits: []}
      callback error, result

  saveSession = (session, callback) ->
    db.put session.id, session, callback

  removeSession = (session, callback) ->
    db.del session.id, callback

  requestHandler = (request, response) ->
    url = parseUrl request.url
    unless url.pathname in ['/t.gif', '/tracked']
      response.writeHead 404
      response.end()
      return

    {id} = querystring.parse url.query
    unless id? and idPattern.test id
      response.writeHead 400
      response.end()
      return

    getSession id, (error, session) ->
      if error?
        console.error "Error loading session #{ id }: #{ error.message }"
        response.writeHead 500
        response.end()
        return

      if url.pathname is '/tracked'
        if request.method is 'DELETE'
          removeSession session, (error) ->
            if error?
              console.error "Error removing session #{ id }: #{ error.message }"
              response.writeHead 500
              response.end()
            else
              response.writeHead 200
              response.end()
          return
        response.writeHead 200, {'Content-Type': 'application/json'}
        response.write JSON.stringify session
        response.end()
        return

      hit =
        time: Date.now()
        userAgent: request.headers['user-agent'] ? 'Unknown'
        remoteAddr: request.headers['x-real-ip'] ? request.headers['x-forwarded-for'] ? request.connection.remoteAddress

      console.log id, JSON.stringify hit

      session.hits.push hit

      saveSession session, (error) ->
        console.error "Error saving session #{ id }: #{ error.message }" if error?

      response.writeHead 200,
        'Content-Type': 'image/gif'
        'Cache-Control': 'no-cache'
        'Pragma': 'no-cache'
        'Expires': '0'
      response.write transparentGif, 'binary'
      response.end()

  server = new Server requestHandler
  server.listen opts.port, (error) ->
    throw error if error?
    console.log "Running on port #{ opts.port }"


module.exports = main