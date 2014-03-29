# Description:
#   Queries Thruk for informations about Nagios status
#
# Configuration:
#   HUBOT_THRUK_URL
#   HUBOT_THRUK_AUTH
#
# Commands:
#   nagios (alerts|wtf) - return nagios alert(s)
#   nagios (summary|status) - return nagios status summary
#
# Author:
#   bdossantos

queries =
  alerts: '/cgi-bin/status.cgi?servicestatustypes=28&style=detail&hoststatustypes=15&hostgroup=all&view_mode=json'
  status: '/cgi-bin/status.cgi?host=all&view_mode=json'

thruk_request = (msg, path, handler) ->
  url = process.env.HUBOT_THRUK_URL

  req = msg.http(url + path)
  if process.env.HUBOT_THRUK_AUTH
    auth = new Buffer(process.env.HUBOT_THRUK_AUTH).toString('base64')
    req.headers Authorization: "Basic #{auth}"

  req.get() (err, res, body) ->
    if err
      return msg.send "Encountered an error :( #{err}"
    if res.statusCode isnt 200
      return msg.send "Request didn't come back HTTP 200 :( #{res.statusCode}"

    try
      content = JSON.parse(body)
    catch error
      return msg.send "Ran into an error parsing JSON :("

    handler content

module.exports = (robot) ->
  robot.hear /nagios (alerts|wtf)/i, (msg) ->
    thruk_request msg, queries.alerts, (datas) ->
      alerts_count = datas.length
      return msg.send "All systems operational" if alerts_count == 0

      response = "Monitoring #{alerts_count} alert(s) :\n\n"
      for alert in datas
        response += "#{alert.host_name} | #{alert.description} | #{alert.plugin_output}\n"

      msg.send response

  robot.hear /nagios (status|summary)/i, (msg) ->
    thruk_request msg, queries.status, (datas) ->
      ok = warning = unknown = critical = 0
      up = down = unreachable = 0

      for alert in datas
        # process services
        if alert.check_type == 0
          switch alert.state
            when 0 then ok += 1
            when 1 then warning += 1
            when 2 then critical += 1
            when 3 then unknown += 1

        # process hosts
        if alert.check_type == 1
           switch alert.state
            when 0 then up += 1
            when 1 then down += 1
            when 2 then unreachable += 1

      response =  "Host => \n"
      response += "up : #{up} | down : #{down} | unreachable : #{unreachable}\n"
      response += "Services => \n"
      response += "ok : #{ok} | warning : #{warning} | critical : #{critical} | unknown : #{unknown}"

      msg.send response
