/mob
	icon = 'sprite/human.dmi'

/mob/Login()
	if(!client.mob || !(istype(client.mob,/mob/player)))
		var/mob/player/P = new
		client.mob = P
		spawn(5)
			P.playerSheet()
	..()

/mob/player
	name = "unnamed"
	icon = 'sprite/human.dmi'
	icon_state = "skeleton_s"
	var/datum/playerFile/playerData = new
	var/hasReroll = TRUE
	var/list/persistingEffects = list()
	var/active_states = 0
	var/passive_states = 0

/mob/player/New()
	randomise()
	..()

/mob/player/Stat()
	for(var/datum/stat/S in playerData.playerStats)
		if(S.isLimited)
			stat("[S.statName]: [S.statModified]/[S.statMax]")
		else
			stat("[S.statName]: [S.statModified]")

/mob/player/verb/say(msg as text)
	chatSay(msg)

/mob/player/proc/takeDamage(var/amount,var/type=DTYPE_BASIC)
	var/damage = type == DTYPE_DIRECT ? amount : amount - playerData.def
	var/doDamage = FALSE
	if(damage > playerData.con)
		if(type == DTYPE_NONLETHAL)
			if(!savingThrow(src,0,SAVING_FORTITUDE))
				//set unconcious 1d4 rounds
			else
				//set dazed 1 round
		type = DTYPE_MASSIVE
	if(type == DTYPE_BASIC || type == DTYPE_DIRECT)
		doDamage = TRUE
	if(type == DTYPE_MASSIVE)
		if(!savingThrow(src,0,SAVING_FORTITUDE))
			playerData.hp.statCur = -1
			doDamage = FALSE
		else
			doDamage = TRUE
	if(doDamage)
		playerData.hp.change(-damage)
		if(playerData.hp.statCur == 0)
			mobAddFlag(src,PASSIVE_STATE_DISABLED,active=0)
		else if(playerData.hp.statCur <= -1 && playerData.hp.statCur >= -9)
			mobRemFlag(src,PASSIVE_STATE_DISABLED,active=0)
			mobAddFlag(src,ACTIVE_STATE_DYING,active=1)
		else if(playerData.hp.statCur <= -10)
			mobRemFlag(src,PASSIVE_STATE_DISABLED,active=0)
			mobRemFlag(src,ACTIVE_STATE_DYING,active=1)
			mobAddFlag(src,PASSIVE_STATE_DEAD,active=0)

/mob/player/proc/randomise()
	var/choice = pick("Human","Golem","Lizard","Slime","Pod","Fly","Jelly","Ape")
	var/chosen = text2path("/datum/race/[choice]")
	genderChange(pick("Male","Female"))
	raceChange(chosen,FALSE)
	eyeChange(pick("red","blue","green","yellow","orange","purple"))
	rerollStats(FALSE)

/mob/player/proc/nameChange(var/toName)
	if(toName)
		name = "[toName] the [playerData.returnGender()] [playerData.playerRace.raceName]"
		playerData.playerName = toName

/mob/player/proc/raceChange(var/datum/race/toRace,var/reselect = TRUE)
	if(toRace)
		playerData.playerRace = new toRace
		playerData.assignRace(playerData.playerRace)
		var/prefix = ""
		if(reselect)
			if(playerData.playerRace.icon_prefix.len > 1)
				prefix = input(src,"Choose a skin") as null|anything in playerData.playerRace.icon_prefix
			else
				prefix = playerData.playerRace.icon_prefix[1]

			playerData.playerRacePrefix = prefix

			if(playerData.playerRace.shouldColorRace)
				playerData.playerColor = input(src,"Choose a Color") as color|null
			else
				playerData.playerColor = "white"
		else
			prefix = playerData.playerRacePrefix

		icon_state = "blank"
		overlays.Cut()

		var/state = "[prefix]_[playerData.playerGenderShort]_s"
		var/image/player = image(icon,state)
		player.color = playerData.playerColor
		overlays.Add(player)

		if(playerData.playerRace.race_overlays.len > 0)
			for(var/ov in playerData.playerRace.race_overlays)
				var/image/race_overlay = image(icon,ov)
				overlays.Add(race_overlay)

		var/image/eyes = image(icon,playerData.playerRace.raceEyes)
		eyes.color = playerData.eyeColor
		overlays.Add(eyes)

		descChange()

/mob/player/proc/genderChange(var/toGender)
	if(toGender)
		if(toGender == "Male")
			playerData.playerGender = 0
			playerData.playerGenderShort = "m"
		if(toGender == "Female")
			playerData.playerGender = 1
			playerData.playerGenderShort = "f"
		if(toGender == "Custom")
			playerData.playerGender = 2
			playerData.customGender = input(src,"Please input your gender") as text
			var/choice = input(src,"Please choose what gender appearence you would like") as anything in list("Male","Female")
			switch(choice)
				if("Male")
					playerData.playerGenderShort = "m"
				if("Female")
					playerData.playerGenderShort = "f"
		raceChange(text2path("[playerData.playerRace]"),FALSE)

/mob/player/proc/eyeChange(var/toColor)
	if(toColor)
		playerData.eyeColor = toColor
		raceChange(text2path("[playerData.playerRace]"),FALSE)

/mob/player/proc/descChange(var/extra)
	playerData.playerDesc = ""

	if(extra)
		playerData.playerExtraDesc += extra
	playerData.playerDesc += "<br>[playerData.playerName] is a [playerData.returnGender()] [playerData.playerRace.raceName].<br>"
	playerData.playerDesc += "[playerData.playerName] has both <font color=[playerData.eyeColor]>eyes</font>.<br>"
	for(var/s in playerData.playerExtraDesc)
		playerData.playerDesc += s
		playerData.playerDesc += "<br>"

/mob/player/proc/descRemove(var/what)
	playerData.playerExtraDesc -= what
	descChange()

/mob/player/proc/rerollStats(var/prompt=TRUE)
	var/min = 2
	var/max = 17
	//min/max are minus 1 for 1 starting score
	playerData.def.setTo(rand(min,max))
	playerData.str.setTo(rand(min,max))
	playerData.dex.setTo(rand(min,max))
	playerData.con.setTo(rand(min,max))
	playerData.wis.setTo(rand(min,max))
	playerData.int.setTo(rand(min,max))
	playerData.cha.setTo(rand(min,max))
	playerData.save.setTo(rand(min,max))
	playerData.fort.setTo(rand(min,max))
	playerData.ref.setTo(rand(min,max))
	playerData.will.setTo(rand(min,max))
	if(prompt)
		var/statAsString = ""
		for(var/datum/stat/S in playerData.playerStats)
			if(!S.isLimited)
				statAsString += "[S.statName]: [S.statModified]\n"
		statAsString += "\nKeeping the stats will confirm your character, locking you from changing it further."
		var/answer = alert(src,statAsString,"Keep these stats?","Keep","Back","Reroll")
		if(answer == "Reroll")
			if(hasReroll)
				rerollStats()
		if(answer == "Back")
			for(var/datum/stat/S in playerData.playerStats)
				S.revert(TRUE)
			src.playerSheet()
		else
			hasReroll = FALSE

/mob/player/verb/playerSheet()
	set name = "View Player Sheet"
	var/html = "<title>Player Sheet</title><html><center>[parseIcon(src.client,src,FALSE)]<br><body style='background:grey'>"
	html += "<b>Name</b>: [playerData.playerName][hasReroll ? " - <a href=?src=\ref[src];function=name><i>Change</i></a>" : ""]<br>"
	html += "<b>Gender</b>: [playerData.returnGender()][hasReroll ? " - <a href=?src=\ref[src];function=gender><i>Change</i></a>" : ""]<br>"
	html += "<b>Race</b>: <font color=[playerData.playerColor]>[playerData.playerRace.raceName]</font>[hasReroll ? " - <a href=?src=\ref[src];function=race><i>Change</i></a>" : ""]<br>"
	html += "<b>Eye Color</b>: <font color=[playerData.eyeColor]>Preview</font>[hasReroll ? " - <a href=?src=\ref[src];function=eyes><i>Change</i></a>" : ""]<br>"
	html += "<b>Description</b>: [playerData.playerDesc] - <a href=?src=\ref[src];function=desc><i>Add</i></a>/<a href=?src=\ref[src];function=descdelete><i>Remove</i></a><br><br>"
	for(var/datum/stat/S in playerData.playerStats)
		if(S.isLimited)
			html += "<b>[S.statName]</b>: [S.statModified]/[S.statMax]<br>"
		else
			html += "<b>[S.statName]</b>: [S.statModified]<br>"
	html += "[hasReroll ? "<a href=?src=\ref[src];function=statroll><b>Reroll Stats</b></a>" : ""]<br>"
	html += "</body></center></html>"
	src << browse(html,"window=playersheet")

/mob/player/Topic(href,href_list[])
	var/function = href_list["function"]
	switch(function)
		if("name")
			nameChange(input(src,"Choose your name") as text)
			src.playerSheet()
		if("race")
			var/choice = input(src,"Choose your Race") as anything in list("Human","Golem","Lizard","Slime","Pod","Fly","Jelly","Ape")
			var/chosen = text2path("/datum/race/[choice]")
			raceChange(chosen)
			nameChange(src.playerData.playerName)
			src.playerSheet()
		if("gender")
			genderChange(input(src,"Choose your Gender") as anything in list ("Male","Female","Custom"))
			nameChange(src.playerData.playerName)
			src.playerSheet()
		if("eyes")
			eyeChange(input(src,"Choose your Eye Color") as color)
			src.playerSheet()
		if("desc")
			descChange(input(src,"Describe anything extra about your character") as text)
			src.playerSheet()
		if("descdelete")
			descRemove(input(src,"Remove what character note?") as null|anything in playerData.playerExtraDesc)
			src.playerSheet()
		if("statroll")
			rerollStats()
			src.playerSheet()