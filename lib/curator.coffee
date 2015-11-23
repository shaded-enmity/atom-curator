CuratorView = require './curator-view'
{CompositeDisposable} = require 'atom'

module.exports = Curator =
  curatorView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @curatorView = new CuratorView(state.curatorViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @curatorView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'curator:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @curatorView.destroy()

  serialize: ->
    curatorViewState: @curatorView.serialize()

  toggle: ->
    console.log 'Curator was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
