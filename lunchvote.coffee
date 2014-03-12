# Description:
#   Suggest lunch destinations and track votes
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_FOURSQUARE_ID = <Fs client id>
#   HUBOT_FOURSQUARE_KEY = <Fs client secret>
#
# Commands:
#   hubot what's for lunch? - Get a list of lunch places
#   hubot reroll - get a new list of options
#   +1 [a, b, or c] - cast a vote for the specified lunch option
#
# Author:
#   Ken V

FS_BASE = "https://api.foursquare.com/v2/"

FS_LL = "37.392415,-122.079767"
FS_EXPLORE_URL = "venues/explore/?" + FS_LL + "&section=food&limit=40&openNow=0&price=1,2&radius=500&query=meal&client_id=GGZ0GOAID2MWSTLTX5TO5SOE2ANLJEP1UUWAVWENIRLFJDBH&client_secret=CVPIJ5PC2DCOPV1HYU5SKA05VC4IANFTPGVOX4RTICI21GFH&v=20140310&time=any"

locations = []
options = ["a", "b", "c", "d"]
options_string = ""
today_names = []
today_votes = 0
today_locations = []
place = ""
votes = {}

    
save = (robot) ->
    robot.brain.data.votes = votes
    
add_vote = (place) ->
    votes[place] ?= 0
    votes[place]++

fetch_locations = (msg) ->
    url = FS_BASE + FS_EXPLORE_URL
    msg.http(url)
        .header('Accept', 'application/json')
        .get() (err, res, body) ->
            result = JSON.parse(body)
            locations = result.response.groups[0].items
            
            # Hold the randomized suggestions in a string, for cleaner printing
            options_string = ""
            options_string += "Lunch suggestions: \n"
            for o in options
                location = msg.random locations
                locations = locations.filter (loc) -> loc isnt location
                options_string += o + " : " + location.venue.name + "\n"
                today_locations.push location
            msg.send(options_string)
            
            today_names = (x.venue.name for x in today_locations)      
            # currently unused, but could be useful
            
module.exports = (robot) ->
    
    robot.respond /reroll/i, (msg) ->
        today_locations = []
        fetch_locations(msg)
        
    robot.respond /what'?s for lunch\??/i, (msg) ->
        if today_locations < 1
            fetch_locations(msg)
        else            
            msg.send(options_string)

    robot.hear /^\+1 (\w).*/i, (msg) ->
        # +1 [a || b || c]
        today_votes++ # currently unused
        vote = msg.match[1] if msg.match[1] in options
        if vote
            # valid place
            add_vote(vote)
            save(robot)
            msg.send(votes[vote] + " for " + vote) 
        else
            #msg.send("invalid vote")
            
    robot.respond /what'?s the count\??/i, (msg) ->
        # hold the output in a single string for cleaner printing
        count_string = "Votes:\n"
        for o in options
            votes[o] ?= 0
            count_string += o + " : " + votes[o] + "\n"
        msg.send(count_string)
            
    # add some kind of tally-fetching command
    # msg.send "Total votes for " + place + ": " + votes[place]
    # 
