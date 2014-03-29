chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'thruk', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/thruk')(@robot)

  it 'registers nagios alerts hear listener', ->
    expect(@robot.hear).to.have.been.calledWith(/nagios (alerts|wtf)/i)

  it 'registers nagios status hear listener', ->
    expect(@robot.hear).to.have.been.calledWith(/nagios (status|summary)/i)
