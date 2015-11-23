# {$, $$$, View} = require 'atom-space-pen-views'
#roaster = require 'roaster'
#fs = require 'fs'
#cheerio = require 'cheerio'
https = require 'https'

host = 'https://scp.artifactoryonline.com/scp'
repo = 'npm'

master = 'https://127.0.0.1/jenkins'

propMap = {
  'npm.name': 'NPM Name: ',
  'npm.version': 'Version: ',
  'sha256': 'Digest: sha256:',
  'name': 'Name: '
}

statsMap = {
  'size': 'Size: ',
  'downloadUri': 'Download: ',
  'lastUpdated': 'Updated: ',
  'created': 'Created: ',
  'createdBy': 'Owner: '
}

ecosystems = {
  'npm': '/.npm'
}

module.exports =
class CuratorView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('curator')
    # Create message element
    this.curate('recast')

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  getProperties: (doc, base...) ->
    items = base || []
    for key, value of doc
      items.push([key, value])
    items

  appendLine: (text) ->
    message = document.createElement('div')
    message.textContent = text
    message.classList.add('message')
    @element.appendChild(message)

  scheduleJob: (ecosystem, pkgname) ->
    console.log "scheduling job for package #{pkgname} in #{ecosystem}"

  findArtifact: (ecosystem, name, found, notfound) ->
    self = this
    path = ecosystems[ecosystem]

    req = https.get "#{host}/#{ecosystem}/#{path}/#{name}/package.json", (res) ->
      if res.statusCode != 404
        data = ''
        res.on 'data', (chunk) ->
          data += chunk.toString()
        res.on 'end', () ->
          md = JSON.parse(data)
          found md['dist-tags']['latest']
      else
        notfound()

  getMetadata: (ecosystem, item) ->
    self = this

    req = https.get "#{host}/api/storage/#{ecosystem}/#{item}", (res) ->
      if res.statusCode != 404
        data = ''
        res.on 'data', (chunk) ->
          data += chunk.toString()
        res.on 'end', () ->
          md = JSON.parse(data)
          console.log md
          # cherry-pick only the statistics we want
          for key, value of statsMap
            name = value + md[key]
            self.appendLine(name)
    req.on 'error', (err) ->
      self.artifactoryDown

    req = https.get "#{host}/api/storage/#{ecosystem}/#{item}?properties", (res) ->
      if res.statusCode != 404
        data = ''
        res.on 'data', (chunk) ->
          data += chunk.toString()
        res.on 'end', () ->
          md = JSON.parse(data)
          console.log md
          defaults = ['name', [item]]
          props = self.getProperties(md['properties'], defaults)
          # all external properties should be known
          for item in props
            name = propMap[item[0]] + item[1].join(',')
            self.appendLine(name)
    req.on 'error', (err) ->
      self.artifactoryDown

  # Obtain metadata or schedule job
  # GET /api/storage/{repoKey}/{itemPath}?properties[=x[,y]]
  curate: (item) ->
    self = this
    console.log "[+] Curating: #{item}"
    self.findArtifact('npm', item,
      (latest) ->
        console.log "#{item}-#{latest}"
        self.getMetadata(repo, "#{item}-#{latest}.tgz")
      ,() ->
        self.scheduleJob(repo, item)
    )

  artifactoryDown: ->
    message = document.createElement('div')
    message.textContent = "Artifactory is down"
    message.classList.add('message')
    @element.appendChild(message)

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
