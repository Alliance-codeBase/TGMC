//TODO: Fix font bad quality

/atom/movable/screen/text/lobby/clickable/setup_character
	maptext = "<span class='lobbytext'>ПЕРСОНАЖ ЗАГРУЖАЕТСЯ</span>"

/atom/movable/screen/text/lobby/clickable/join_game
	maptext = "<span class='lobbytext'>ПРИСОЕДИНИТЬСЯ</span>"

/atom/movable/screen/text/lobby/clickable/join_game/update_text()
	var/mob/new_player/player = hud.mymob
	if(SSticker?.current_state > GAME_STATE_PREGAME)
		maptext = "<span class='lobbytext'>ПРИСОЕДИНИТЬСЯ</span>"
		icon_state = "join"
		remove_atom_colour(FIXED_COLOR_PRIORITY, unhighlighted_color)
		return
	remove_atom_colour(FIXED_COLOR_PRIORITY, unhighlighted_color)
	unhighlighted_color = player.ready ? COLOR_GREEN : COLOR_RED
	add_atom_colour(unhighlighted_color, FIXED_COLOR_PRIORITY)
	maptext = "<span class='lobbytext'>ВЫ [player.ready ? "" : "НЕ "]ГОТОВЫ</span>"
	icon_state = player.ready ? "ready" : "unready"

/atom/movable/screen/text/lobby/clickable/observe
	maptext = "<span class='lobbytext'>ЗА ПРИЗРАКА</span>"

/atom/movable/screen/text/lobby/clickable/manifest
	maptext = "<span class='lobbytext'>МАНИФЕСТ</span>"

/atom/movable/screen/text/lobby/clickable/xenomanifest
	maptext = "<span class='lobbytext'>ЛИДЕРЫ ГНЕЗДА</span>"

/atom/movable/screen/text/lobby/clickable/background
	maptext = "<span class='lobbytext'>БЕКСТЕЙДЖ</span>"

/atom/movable/screen/text/lobby/clickable/changelog
	maptext = "<span class='lobbytext'>СПИСОК ИЗМЕНЕНИЙ</span>"

/atom/movable/screen/text/lobby/clickable/polls
	maptext = "<span class='lobbytext'>ОПРОСЫ</span>"

/atom/movable/screen/text/lobby/clickable/polls/update_text()
	INVOKE_ASYNC(src, PROC_REF(fetch_polls))

/atom/movable/screen/text/lobby/clickable/polls/fetch_polls()
	var/mob/new_player/player = hud.mymob
	var/hasnewpolls = player.check_playerpolls()
	if(isnull(hasnewpolls))
		maptext = "<span class='lobbytext'>ОТСУТСТВУЕТ БД!</span>"
		return
	maptext = "<span class='lobbytext'>ПОКАЗАТЬ ОПРОСЫ[hasnewpolls ? " (НОВОЕ!)" : ""]</span>"

/atom/movable/screen/text/lobby/clickable/modpacks
	maptext = "<span class='lobbytext'>МОДИФИКАЦИИ</span>"