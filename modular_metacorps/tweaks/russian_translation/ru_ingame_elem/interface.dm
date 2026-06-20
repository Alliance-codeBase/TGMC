// code/__HELPERS/announce.dm

#define span_alert_header(str) ("<span class='alert_header'>" + str + "</span>")
#define span_faction_alert_title(str) ("<span class='faction_alert_title'>" + str + "</span>")
#define span_faction_alert_minortitle(str) ("<span class='faction_alert_minortitle'>" + str + "</span>")
#define span_faction_alert_subtitle(str) ("<span class='faction_alert_subtitle'>" + str + "</span>")
#define span_faction_alert_text(str) ("<span class='faction_alert_text'>" + str + "</span>")
#define faction_alert_default_span(string) ("<div class='faction_alert_default'>" + string + "</div>")
#define faction_alert_colored_span(color, string) ("<div class='faction_alert_" + color + "'>" + string + "</div>")

proc/priority_announce(
	message,
	title = "Оповещение",
	subtitle = "",
	type = ANNOUNCEMENT_REGULAR,
	sound = 'sound/misc/notice2.ogg',
	channel_override = CHANNEL_ANNOUNCEMENTS,
	color_override,
	list/receivers = (GLOB.alive_human_list + GLOB.ai_list + GLOB.observer_list),
	playing_sound = TRUE
)
	if(!message)
		return


	// header/subtitle to use when using assemble_alert()
	var/assembly_header
	var/assembly_subtitle
	switch(type)
		if(ANNOUNCEMENT_REGULAR)
			assembly_header = title

		if(ANNOUNCEMENT_PRIORITY)
			assembly_header = "Приоритетное Оповещение"
			if(length(title) > 0)
				assembly_subtitle = title

		if(ANNOUNCEMENT_COMMAND)
			assembly_header = "Оповещение от Командования"

	if(subtitle && type != ANNOUNCEMENT_PRIORITY)
		assembly_subtitle = subtitle

	var/finalized_announcement
	if(color_override)
		finalized_announcement = assemble_alert(
			title = assembly_header,
			subtitle = assembly_subtitle,
			message = message,
			color_override = color_override
		)
	else
		finalized_announcement = assemble_alert(
			title = assembly_header,
			subtitle = assembly_subtitle,
			message = message
		)

	var/s = sound(sound, channel = channel_override)
	for(var/i in receivers)
		var/mob/M = i
		if(!isnewplayer(M))
			to_chat(M, finalized_announcement)
			if(playing_sound)
				SEND_SOUND(M, s)

proc/print_command_report(papermessage, papertitle = "paper", announcemessage = "Отчет был установлен и распечатан на всех консолях связи.", announcetitle = "Входящее Зашифрованное Сообщение", announce = TRUE)

proc/level_announce(datum/security_level/selected_level, previous_level_number)
	var/current_level_number = selected_level.number_level
	var/current_level_name = selected_level.name
	var/current_level_color = selected_level.announcement_color

	var/active_subtitle
	var/active_message
	var/active_sound

	if(current_level_number > previous_level_number)
		active_subtitle = "Уровень безопасности был повышен до [uppertext(current_level_name)]:"
		active_message = selected_level.elevating_body
		active_sound = selected_level.elevating_sound
	else
		active_subtitle = "Уровень безопасности был понижен до [uppertext(current_level_name)]:"
		active_message = selected_level.lowering_body
		active_sound = selected_level.lowering_sound

	priority_announce(
		type = ANNOUNCEMENT_REGULAR,
		title = "Внимание!",
		subtitle = active_subtitle,
		message = active_message,
		sound = active_sound,
		color_override = current_level_color
	)

proc/minor_announce(message, title = "Внимание:", alert, list/receivers = GLOB.alive_human_list, should_play_sound = FALSE)
	if(!message)
		return

	var/sound/S = alert ? sound('sound/misc/notice1.ogg') : sound('sound/misc/notice2.ogg')
	S.channel = CHANNEL_ANNOUNCEMENTS
	for(var/mob/M AS in receivers)
		if(!isnewplayer(M) && !isdeaf(M))
			to_chat(M, assemble_alert(
				title = title,
				message = message,
				minor = TRUE
			))
			if(should_play_sound)
				SEND_SOUND(M, S)

#undef span_alert_header
#undef span_faction_alert_title
#undef span_faction_alert_minortitle
#undef span_faction_alert_subtitle
#undef span_faction_alert_text
#undef faction_alert_default_span
#undef faction_alert_colored_span

// code/__HELPERS/type2type.dm

dir2text(direction)
	switch(direction)
		if(NORTH)
			return "север"
		if(SOUTH)
			return "юг"
		if(EAST)
			return "восток"
		if(WEST)
			return "запад"
		if(NORTHEAST)
			return "северо-восток"
		if(SOUTHEAST)
			return "юго-восток"
		if(NORTHWEST)
			return "северо-запад"
		if(SOUTHWEST)
			return "юго-запад"

dir2text_short(direction)
	switch(direction)
		if(NORTH)
			return "С"
		if(SOUTH)
			return "Ю"
		if(EAST)
			return "В"
		if(WEST)
			return "З"
		if(NORTHEAST)
			return "СВ"
		if(SOUTHEAST)
			return "ЮВ"
		if(NORTHWEST)
			return "СЗ"
		if(SOUTHWEST)
			return "ЮЗ"

// code/controllers/configuration/entries/game_options.dm

/datum/config_entry/string/alert_delta
	default = "Уничтожение станции неизбежно. Всем членам экипажа предписано подчиняться всем указаниям начальников штаба. Любое нарушение этих приказов может караться устранением на месте. Это не учебная тревога."

// code/controllers/subsystem/evacuation.dm

/datum/controller/subsystem/evacuation/initiate_evacuation(override)
	if(evac_status != EVACUATION_STATUS_STANDING_BY)
		return FALSE
	if(!override && scuttle_flags & (FLAGS_EVACUATION_DENY|FLAGS_SDEVAC_TIMELOCK))
		return FALSE
	GLOB.enter_allowed = FALSE
	evac_time = world.time
	evac_status = EVACUATION_STATUS_INITIATING
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_EVACUATION_STARTED)
	var/sec_level_changed = SSsecurity_level.set_level(SEC_LEVEL_DELTA, FALSE) // TRUE if we weren't already on Delta alert
	priority_announce(
		type = ANNOUNCEMENT_PRIORITY,
		title = "[sec_level_changed ? "Код Дельта. Введен режим чрезвычайной ситуации." : ""]Инициализация эвакуации через [EVACUATION_AUTOMATIC_DEPARTURE/600] минут.",
		message = "Режим Экстренной Эвакуации был активирован. Проследуйте на спасательные капсулы.[sec_level_changed ? "\n\n[CONFIG_GET(string/alert_delta)]" : ""]",
		sound = 'sound/AI/evacuate.ogg',
		color_override = sec_level_changed ? "purple" : "orange"
	)
	xeno_message("По гнезду прокатывается волна адреналина. Эти существа из плоти пытаются сбежать!")
	pod_list = SSshuttle.escape_pods.Copy()
	for(var/obj/docking_port/mobile/escape_pod/pod AS in pod_list)
		pod.prep_for_launch()
	return TRUE

/datum/controller/subsystem/evacuation/begin_launch()
	if(evac_status != EVACUATION_STATUS_INITIATING)
		return FALSE
	evac_status = EVACUATION_STATUS_IN_PROGRESS
	priority_announce("ВНИМАНИЕ: Приказ об Эвакуации подтвержден. Начат запуск спасательных капсул.", title = "Экстренная Эвакуация", type = ANNOUNCEMENT_PRIORITY, sound = 'sound/AI/evacuation_confirmed.ogg', color_override = "orange")
	return TRUE

/datum/controller/subsystem/evacuation/cancel_evacuation()
	if(evac_status != EVACUATION_STATUS_INITIATING)
		return FALSE
	GLOB.enter_allowed = TRUE
	evac_time = null
	evac_status = EVACUATION_STATUS_STANDING_BY
	priority_announce("Приказ об Эвакуации отменен.", title = "Экстренная Эвакуация", type = ANNOUNCEMENT_PRIORITY, sound = 'sound/AI/evacuate_cancelled.ogg', color_override = "orange")
	for(var/obj/docking_port/mobile/escape_pod/pod AS in pod_list)
		pod.unprep_for_launch()
	return TRUE

/datum/controller/subsystem/evacuation/announce_evac_completion()
	priority_announce("ВНИМАНИЕ: Приказ об Эвакуации выполнен.", title = "Экстренная Эвакуация", type = ANNOUNCEMENT_PRIORITY, sound = 'sound/AI/evacuation_complete.ogg', color_override = "orange")
	evac_status = EVACUATION_STATUS_COMPLETE

// code/controllers/configuration/entries/general.dm

/datum/config_entry/string/client_warn_message
	default = "В вашей версии BYOND могут возникнуть технические проблемы, доступ к этому серверу может быть заблокирован в будущем."

/datum/config_entry/string/client_error_message
	default = "Ваша версия BYOND слишком старая, могут быть проблемы и доступ к этому серверу может быть заблокирован в будущем."

// code/datums/actions/order_action.dm

#define ATTACK_ORDER "attack"
#define DEFEND_ORDER "defend"
#define RETREAT_ORDER "retreat"
#define RALLY_ORDER "rally"

GLOBAL_LIST_INIT(ru_order_to_message, list(
	ATTACK_ORDER = list(";МОРПЕХИ, В БОЙ! СТРЕЛЯЙТЕ! УБЕЙТЕ ИХ!!", ";УНИЧТОЖИТЬ ИХ!", ";НАКОРМИТЕ ИХ СВИНЦОМ!", ";ПОКОНЧИТЬ С НИМИ!", ";АТАКУЙТЕ ЗДЕСЬ!", ";В АТАКУ!", ";ЗАДАВИМ ИХ!", ";УЕБЁМ ИХ!", ";ПОКАЖЕМ ИМ ГДЕ ЗДЕСЬ РАКИ ЗИМУЮТ!", ";ПОКАЖИТЕ ЭТИМ ТВАРЯМ КУЗЬКИНУ МАТЬ!"),
	DEFEND_ORDER = list(";УКРОЙТЕСЬ И ПРИКРОЙТЕ!", ";УДЕРЖИВАТЬ ЛИНИЮ!", ";ДЕРЖАТЬ ПОЗИЦИИ!", ";СТОЙТЕ НА СВОЕЙ ПОЗИЦИИ!", ";ОСТАНОВИТЕСЬ И ОТСТРЕЛИВАЙТЕСЬ!", ";УКРОЙТЕСЬ!", ";ЗАЩИЩАЙТЕ ТЕРРИТОРИЮ!", ";ПРИГОТОВЬТЕСЬ К УКРЫТИЮ!", ";В УКРЫТИЕ!", ";ОНИ ИДУТ!", ";ОСТАНОВИТЬ ПРОДВИЖЕНИЕ! ОСТАВАЙТЕСЬ ЗДЕСЬ!", ";ПРИБЛИЖАЮТСЯ!"),
	RETREAT_ORDER = list(";ОТСТУПАЙТЕ! ОТСТУПАЙТЕ!", ";УХОДИМ ОТСЮДА!", ";НЕ УМИРАЙТЕ ЗДЕСЬ! БЕГИТЕ!", ";БЕГИТЕ! БЕГИТЕ И СПАСАЙТЕ СВОИ ЖИЗНИ!", ";ВЫХОДИМ ИЗ БОЯ! ПОВТОРЯЮ, ВЫХОДИМ ИЗ БОЯ!", ";УСТУПИТЕ ЗЕМЛЮ! УСТУПИТЕ ЖЕ ЕЁ!", ";СЪЁБЫВАЕМ ОТСЮДА!"),
	RALLY_ORDER = list(";КО МНЕ МОИ МУЖЧИНЫ!", ";ПЕРЕГРУППИРУЕМСЯ У МЕНЯ!", ";СЛЕДУЙТЕ ЗА МНОЙ!", ";МНЕ НУЖНА ПОДДЕРЖКА!", ";ВПЕРЁД!"),
	))

/datum/action/innate/order
	var/nc_verb_name = ""

/datum/action/innate/order/send_order(atom/target, datum/squad/squad, faction = FACTION_TERRAGOV)
	if(!can_use_action())
		return
	to_chat(owner ,span_ordercic("Вы приказали морпехам [nc_verb_name] [get_area(target.loc)]!"))
	owner.playsound_local(owner, "sound/effects/CIC_order.ogg", 10, 1)
	if(visual_type)
		target = get_turf(target)
		new visual_type(target, faction)
	TIMER_COOLDOWN_START(owner, COOLDOWN_CIC_ORDERS, CIC_ORDER_COOLDOWN)
	SEND_SIGNAL(owner, COMSIG_CIC_ORDER_SENT)
	addtimer(CALLBACK(src, PROC_REF(on_cooldown_finish)), CIC_ORDER_COOLDOWN + 1)
	if(squad)
		for(var/mob/living/carbon/human/marine AS in squad.marines_list)
			marine.receive_order(target, arrow_type, verb_name, faction)
		return TRUE
	for(var/mob/living/carbon/human/human AS in GLOB.alive_human_list)
		if(human.faction == faction)
			human.receive_order(target, arrow_type, verb_name, faction)
	return TRUE

/mob/living/carbon/human/receive_order(atom/target, arrow_type, verb_name = "rally", faction)
	if(!target || !arrow_type)
		return
	if(!(job.job_flags & JOB_FLAG_CAN_SEE_ORDERS))
		return
	if(z != target.z)
		return
	if(target == src)
		return
	var/hud_type
	switch(faction)
		if(FACTION_TERRAGOV)
			hud_type = DATA_HUD_SQUAD_TERRAGOV
		if(FACTION_SOM)
			hud_type = DATA_HUD_SQUAD_SOM
		else
			return
	var/datum/atom_hud/squad/squad_hud = GLOB.huds[hud_type]
	if(!squad_hud.hudusers[src])
		return
	var/atom/movable/screen/arrow/arrow_hud = new arrow_type
	arrow_hud.add_hud(src, target)
	playsound_local(src, "sound/effects/CIC_order.ogg", 20, 1)
	to_chat(src,span_ordercic("Командование призывает нас к <b>[verb_name]</b> [get_area(get_turf(target))]!"))

/datum/action/innate/order/selectable/swap_order(new_order)
	if(!new_order || new_order == current_order)
		return FALSE

	current_order = new_order

	switch(current_order)
		if(ATTACK_ORDER)
			name = "Отправить приказ об атаке"
			action_icon_state = "attack"
			verb_name = "атаке врага в"
			nc_verb_name = "атаковать врага в"
			arrow_type = /atom/movable/screen/arrow/attack_order_arrow
			visual_type = /obj/effect/temp_visual/order/attack_order
		if(DEFEND_ORDER)
			name = "Отправить приказ о защите"
			action_icon_state = "defend"
			verb_name = "защищите своих позиций в"
			nc_verb_name = "защищать свои позиций в"
			arrow_type = /atom/movable/screen/arrow/defend_order_arrow
			visual_type = /obj/effect/temp_visual/order/defend_order
		if(RETREAT_ORDER)
			name = "Отправить приказ об отступлении"
			action_icon_state = "retreat"
			verb_name = "отступлению от"
			nc_verb_name = "отступать от"
			arrow_type = /atom/movable/screen/arrow/retreat_order_arrow
			visual_type = /obj/effect/temp_visual/order/retreat_order
		if(RALLY_ORDER)
			name = "Отправить приказ о перегруппировке"
			action_icon_state = "rally"
			verb_name = "перегруппировке у"
			nc_verb_name = "перегруппироваться у"
			arrow_type = /atom/movable/screen/arrow/rally_order_arrow
			visual_type = /obj/effect/temp_visual/order/rally_order

	update_button_icon()

	return TRUE

/datum/action/innate/order/selectable/personal/swap_order(new_order)
	. = ..()
	if(!.)
		return
	message_list = GLOB.ru_order_to_message[current_order]

#undef ATTACK_ORDER
#undef DEFEND_ORDER
#undef RETREAT_ORDER
#undef RALLY_ORDER

// code/datums/emergency_calls/emergency_call.dm

/datum/emergency_call
	dispatch_message = "С находящегося поблизости судна получен зашифрованный сигнал. Оставайтесь на связи."

/datum/emergency_call/show_join_message()
	if(!mob_max || !SSticker?.mode) //Not a joinable distress call.
		return

	for(var/i in GLOB.observer_list)
		var/mob/dead/observer/M = i
		to_chat(M, "<br><font size='3'>[span_attack("Аварийный сигнал активирован. Нажмите <B>Ghost > <a href='byond://?src=[REF(M)];join_ert=1'>Join Response Team</a></b> verb чтобы зайти!")]</font><br>")
		to_chat(M, "[span_attack("Вы не можете зайти если вы Гостнулись до этого сообщения.")]<br>")

/datum/emergency_call/do_activate(announce = TRUE)
	candidate_timer = null
	SSticker.mode.waiting_for_candidates = FALSE

	var/list/valid_candidates = list()

	for(var/i in candidates)
		var/datum/mind/M = i
		if(!istype(M)) // invalid
			continue
		if(M.current) //If they still have a body
			if(!isaghost(M.current) && M.current.stat != DEAD) // and not dead or admin ghosting,
				to_chat(M.current, span_warning("Вас не выбрали в группу реагирования, потому что вы не умерли."))
				continue
		if(name == "Xenomorphs" && is_banned_from(ckey(M.key), ROLE_XENOMORPH))
			if(M.current)
				to_chat(M, span_warning("Вас не выбрали в группу реагирования, потому что вы забанены в категории Ксеноморфов."))
			continue
		valid_candidates += M

	message_admins("Distress beacon: [name] got [length(candidates)] candidates, [length(valid_candidates)] of them were valid.")

	if(mob_min && length(valid_candidates) < mob_min)
		message_admins("Aborting distress beacon [name], not enough candidates. Found: [length(valid_candidates)]. Minimum required: [mob_min].")
		SSticker.mode.waiting_for_candidates = FALSE
		members.Cut() //Empty the members list.
		candidates.Cut()

		if(announce)
			priority_announce("Сигнал бедствия не получил ответа, пусковые трубы сейчас проходят перекалибровку.", "Сигнал Бедствия")

		SSticker.mode.picked_call = null
		SSticker.mode.on_distress_cooldown = TRUE

		cooldown_timer = addtimer(CALLBACK(src, PROC_REF(reset)), COOLDOWN_COMM_REQUEST, TIMER_STOPPABLE)
		return

	var/list/datum/mind/picked_candidates = list()
	if(length(valid_candidates) > mob_max)
		for(var/i in 1 to mob_max)
			if(!length(valid_candidates)) //We ran out of candidates.
				break
			picked_candidates += pick_n_take(valid_candidates) //Get a random candidate, then remove it from the candidates list.

		for(var/datum/mind/M in valid_candidates)
			if(M.current)
				to_chat(M.current, span_warning("Вас не выбрали в группу реагирования. В следующий раз повезет!"))
		message_admins("Distress beacon: [length(valid_candidates)] valid candidates were not selected.")
	else
		picked_candidates = valid_candidates // save some time
		message_admins("Distress beacon: All valid candidates were selected.")

	if(announce)
		priority_announce(dispatch_message, "Сигнал Бедствия", sound = 'sound/AI/distressreceived.ogg')

	message_admins("Distress beacon: [name] finalized, starting spawns.")

	// begin loading the shuttle
	if(!SSmapping.shuttle_templates[shuttle_id])
		message_admins("Distress beacon: [name] couldn't find a valid shuttle template")
		CRASH("ert called with invalid shuttle_id")
	var/datum/map_template/shuttle/S = SSmapping.shuttle_templates[shuttle_id]

	shuttle = SSshuttle.load_template_to_transit(S)
	if(!shuttle)
		message_admins("Distress beacon: shuttle loading failed")
		reset()
		return

	spawn_items()

	if(mob_min > 0)
		if(length(picked_candidates))
			max_medics = max(round(length(picked_candidates) * 0.25), 1)
			for(var/i in picked_candidates)
				var/datum/mind/candidate_mind = i
				members += candidate_mind
				create_member(candidate_mind)
		else
			message_admins("ERROR: No picked candidates, aborting.")
			shuttle.intoTheSunset() // delete
			return

	if(auto_shuttle_launch)
		if(!shuttle.auto_launch())
			shuttle.intoTheSunset()
			message_admins("Distress beacon: [name] couldn't find a valid target to autolaunch")
			CRASH("can't find a valid place to autolaunch ert shuttle towards")

	message_admins("Distress beacon: [name] finished spawning.")

	candidates.Cut() //Blank out the candidates list for next time.

	cooldown_timer = addtimer(CALLBACK(src, PROC_REF(reset)), COOLDOWN_COMM_REQUEST, TIMER_STOPPABLE)

// code/datums/gamemodes/ (im lazy to add specific ones)

/datum/game_mode/infestation/crash/announce()
	to_chat(world, span_round_header("Текущая карта - [SSmapping.configs[GROUND_MAP].map_name]!"))
	priority_announce(
		message = "Высадка запланирована через 10 минут. Подготовьтесь к высадке. Известные враждебные силы вблизи посадочной площадки. Протокол детонации: Активнен. Планета: Одноразовая. Морпехи: Одноразовые.",
		title = "Доброе утро, морпехи.",
		type = ANNOUNCEMENT_PRIORITY,
		color_override = "red"
	)
	playsound(shuttle, 'sound/machines/warning-buzzer.ogg', 75, 0, 30)

/datum/game_mode/extended/announce()
	to_chat(world, "<b>Текущий режим это - Экстендед РолеПлеинг!</b>")
	to_chat(world, "<b>СКИПАЕМ!</b>")

#define BIOSCAN_DELTA(count, delta) count ? max(0, count + rand(-delta, delta)) : 0

#define BIOSCAN_LOCATION(show_locations, location) ((show_locations && location) ? ", including one in [location]" : "")

#define AI_SCAN_DELAY 15 SECONDS

/datum/game_mode/infestation/announce_bioscans(show_locations = TRUE, delta = 2, ai_operator = FALSE, announce_humans = TRUE, announce_xenos = TRUE, send_fax = TRUE)

	if(ai_operator)
		#ifndef TESTING
		var/mob/living/silicon/ai/bioscanning_ai = usr
		if((bioscanning_ai.last_ai_bioscan + COOLDOWN_AI_BIOSCAN) > world.time)
			to_chat(bioscanning_ai, "Приборы Биосканирования все еще проходят калибровку после последнего использования.")
			return
		bioscanning_ai.last_ai_bioscan = world.time
		to_chat(bioscanning_ai, span_warning("Поиск враждебных форм жизни..."))
		if(!do_after(usr, AI_SCAN_DELAY, NONE, usr, BUSY_ICON_GENERIC))
			bioscanning_ai.last_ai_bioscan = 0
			return

		#endif

	else
		TIMER_COOLDOWN_START(src, COOLDOWN_BIOSCAN, bioscan_interval)
	var/list/list/counts = list()
	var/list/list/area/locations = list()

	for(var/trait in GLOB.bioscan_locations)
		counts[trait] = list(FACTION_TERRAGOV = 0, FACTION_XENO = 0)
		locations[trait] = list(FACTION_TERRAGOV = 0, FACTION_XENO = 0)
		for(var/i in SSmapping.levels_by_trait(trait))
			var/list/parsed_xenos = GLOB.hive_datums[XENO_HIVE_NORMAL].xenos_by_zlevel["[i]"]?.Copy()
			for(var/mob/living/carbon/xenomorph/xeno in parsed_xenos)
				if(xeno.xeno_caste.caste_flags & CASTE_NOT_IN_BIOSCAN)
					parsed_xenos -= xeno
			counts[trait][FACTION_XENO] += length(parsed_xenos)
			counts[trait][FACTION_TERRAGOV] += length(GLOB.humans_by_zlevel["[i]"])
			if(length(GLOB.hive_datums[XENO_HIVE_NORMAL].xenos_by_zlevel["[i]"]))
				locations[trait][FACTION_XENO] = get_area(pick(GLOB.hive_datums[XENO_HIVE_NORMAL].xenos_by_zlevel["[i]"]))
			if(length(GLOB.humans_by_zlevel["[i]"]))
				locations[trait][FACTION_TERRAGOV] = get_area(pick(GLOB.humans_by_zlevel["[i]"]))

	var/numHostsPlanet = counts[ZTRAIT_GROUND][FACTION_TERRAGOV]
	var/numHostsShip = counts[ZTRAIT_MARINE_MAIN_SHIP][FACTION_TERRAGOV]
	var/numHostsTransit = counts[ZTRAIT_RESERVED][FACTION_TERRAGOV]
	var/numXenosPlanet = counts[ZTRAIT_GROUND][FACTION_XENO]
	var/numXenosShip = counts[ZTRAIT_MARINE_MAIN_SHIP][FACTION_XENO]
	var/numXenosTransit = counts[ZTRAIT_RESERVED][FACTION_XENO]
	var/host_location_planetside = locations[ZTRAIT_GROUND][FACTION_TERRAGOV]
	var/host_location_shipside = locations[ZTRAIT_MARINE_MAIN_SHIP][FACTION_TERRAGOV]
	var/xeno_location_planetside = locations[ZTRAIT_GROUND][FACTION_XENO]
	var/xeno_location_shipside = locations[ZTRAIT_MARINE_MAIN_SHIP][FACTION_XENO]

	//Adjust the randomness there so everyone gets the same thing
	var/hosts_shipside = BIOSCAN_DELTA(numHostsShip, delta)
	var/xenos_planetside = BIOSCAN_DELTA(numXenosPlanet, delta)
	var/hosts_transit = BIOSCAN_DELTA(numHostsTransit, delta)
	var/xenos_transit = BIOSCAN_DELTA(numXenosTransit, delta)

	var/sound/sound = sound(get_sfx(SFX_QUEEN), channel = CHANNEL_ANNOUNCEMENTS, volume = 50)
	if(announce_xenos)
		for(var/mob/hearer in GLOB.alive_xeno_list_hive[XENO_HIVE_NORMAL])
			SEND_SOUND(hearer, sound)
			to_chat(hearer, assemble_alert(
				title = "Отчет Королевы Матери",
				subtitle = "Королева Мать проникает в ваше сознание...",

				message = "Моим детям и их королеве,<br>Я чувствую [hosts_shipside ? "примерно [hosts_shipside]":"ноль"] \
				носителей в металлическом улье[BIOSCAN_LOCATION(show_locations, host_location_shipside)], \
				[numHostsPlanet || "никто"] из них шляется по планете[BIOSCAN_LOCATION(show_locations, host_location_planetside)] и \
				[hosts_transit ? "примерно [hosts_transit]":"ноль"] носителей на металлической птице в пути.",

				color_override = "purple"
			))

	var/name = "Статус Биосканирования [MAIN_AI_SYSTEM]"

	var/input = {"Биосканирование завершено. Датчики показывают, что [numXenosShip || "нету"] неизвестной формы жизни, которая бы \
	присутствовала на корабле[BIOSCAN_LOCATION(show_locations, xeno_location_shipside)], [xenos_planetside ? "примерно [xenos_planetside]":"ноль"] \
	форм[xenos_planetside > 0 ? "ы":""] жизни расположены предположительно на планете[BIOSCAN_LOCATION(show_locations, xeno_location_planetside)] и [numXenosTransit || "ноль"] \
	неизвестных форм жизни в пути."}

	var/ai_name = "Статус Биосканирования [usr]"

	if(ai_operator)
		priority_announce(input, ai_name, sound = 'sound/AI/bioscan.ogg', color_override = "grey", receivers = (GLOB.alive_human_list + GLOB.ai_list))
		log_game("Bioscan. Humans: [numHostsPlanet] on the planet\
		[host_location_planetside ? " Location:[host_location_planetside]":""] and [numHostsShip] on the ship.\
		[host_location_shipside ? " Location: [host_location_shipside].":""] \
		Xenos: [xenos_planetside] on the planet and [numXenosShip] on the ship\
		[xeno_location_planetside ? " Location:[xeno_location_planetside]":""] and [numXenosTransit] in transit.")

		switch(GLOB.current_orbit)
			if(1)
				to_chat(usr, span_warning("Анализ сигналов позволяет получить превосходные данные о передвижениях и численности враждебных сил."))
				return
			if(3)
				to_chat(usr, span_warning("В наших приборах биосканирования обнаружены незначительные искажения, вызванные подъемом судна на высоту, поэтому некоторая информация о враждебной активности может быть неверной."))
				return
			if(5)
				to_chat(usr, span_warning("В показаниях биосканирования обнаружены серьезные искажения, вызванные подъемом судна на высоту, информация сильно повреждена."))
		return

	if(announce_humans)
		priority_announce(input, name, sound = 'sound/AI/bioscan.ogg', color_override = "grey", receivers = (GLOB.alive_human_list + GLOB.ai_list)) // Hide this from observers, they have their own detailed alert.

	if(send_fax)
		var/fax_message = generate_templated_fax("Боевой Информационный Центр", "[MAIN_AI_SYSTEM] Статус Биосканирования", "", input, "", MAIN_AI_SYSTEM)
		send_fax(null, null, "Боевой Информационный Центр", "[MAIN_AI_SYSTEM] Статус Биосканирования", fax_message, FALSE)

	log_game("Bioscan. Humans: [numHostsPlanet] on the planet[host_location_planetside ? " Location:[host_location_planetside]":""] and [numHostsShip] on the ship.[host_location_shipside ? " Location: [host_location_shipside].":""] Xenos: [xenos_planetside] on the planet and [numXenosShip] on the ship[xeno_location_planetside ? " Location:[xeno_location_planetside]":""] and [numXenosTransit] in transit.")

	for(var/mob/hearer in GLOB.observer_list)
		to_chat(hearer, assemble_alert(
			title = "Детальное Биосканирование",
			message = {"[numXenosPlanet] ксеноморф[numXenosPlanet > 1 ? "ов":""] на планете.
[numXenosShip] ксеноморф[numXenosShip > 1 ? "ов":""] на корабле.
[numXenosTransit] ксеноморф[numXenosTransit > 1 ? "ов":""] в пути.

[numHostsPlanet] персон[numHostsPlanet = 1 ? "а":""] на планет.
[numHostsShip] персон[numHostsShip = 1 ? "а":""] на корабле.
[numHostsTransit] персон[numHostsTransit = 1 ? "а":""] в пути."},
			color_override = "purple"
		))

	message_admins("Bioscan - Humans: [numHostsPlanet] on the planet[host_location_planetside ? ". Location:[host_location_planetside]":""]. [hosts_shipside] on the ship.[host_location_shipside ? " Location: [host_location_shipside].":""]. [hosts_transit] in transit.")
	message_admins("Bioscan - Xenos: [xenos_planetside] on the planet[xenos_planetside > 0 && xeno_location_planetside ? ". Location:[xeno_location_planetside]":""]. [numXenosShip] on the ship.[xeno_location_shipside ? " Location: [xeno_location_shipside].":""] [xenos_transit] in transit.")

#undef BIOSCAN_DELTA
#undef BIOSCAN_LOCATION
#undef AI_SCAN_DELAY

/datum/game_mode/infestation/can_start(bypass_checks = FALSE)
	. = ..()
	if(!.)
		return
	var/xeno_candidate = FALSE //Let's guarantee there's at least one xeno.
	for(var/level = JOBS_PRIORITY_HIGH; level >= JOBS_PRIORITY_LOW; level--)
		for(var/p in GLOB.ready_players)
			var/mob/new_player/player = p
			if(player.client.prefs.job_preferences[ROLE_XENO_QUEEN] == level && SSjob.AssignRole(player, SSjob.GetJobType(/datum/job/xenomorph/queen)))
				xeno_candidate = TRUE
				break
			if(player.client.prefs.job_preferences[ROLE_XENOMORPH] == level && SSjob.AssignRole(player, SSjob.GetJobType(/datum/job/xenomorph)))
				xeno_candidate = TRUE
				break
	if(!xeno_candidate && !bypass_checks)
		to_chat(world, "<b>Невозможно начать [name].</b> Кандидатов ксеносов не обнаружено.")
		return FALSE

/datum/game_mode/infestation/map_announce()
	if(!SSmapping.configs[GROUND_MAP].announce_text)
		return

	priority_announce(
		title = "Обновление Верховного Командования",
		subtitle = "Доброе утро, морпехи.",
		message = "Криосон отключен высшим командованием TGMC.<br><br>ВНИМАНИЕ: [SSmapping.configs[SHIP_MAP].map_name].<br>[SSmapping.configs[GROUND_MAP].announce_text]",
		sound = 'sound/AI/ares_online.ogg',
		color_override = "red"
	)


/datum/game_mode/infestation/announce()
	to_chat(world, span_round_header("Текущая карта - [SSmapping.configs[GROUND_MAP].map_name]!"))

// code/datums/actions/orders.dm

/mob/living/carbon/human/issue_order(command_aura as null|text)
	set hidden = TRUE

	if(skills.getRating(SKILL_LEADERSHIP) < SKILL_LEAD_TRAINED)
		to_chat(src, span_warning("Вы недостаточно компетентны в руководстве, чтобы отдавать приказы."))
		return

	if(stat)
		to_chat(src, span_warning("В вашем текущем состоянии вы не можете отдать приказ."))
		return

	if(IsMute())
		to_chat(src, span_warning("Вы не можете отдать заказ, если ваш микрофон отключен."))
		return

	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_SKILL_ORDERS))
		to_chat(src, span_warning("Вы недавно отдали приказ. Успокойтесь."))
		return

	if(!command_aura)
		command_aura = tgui_input_list(src, "Выберите приказ", items = command_aura_allowed + "помощь")
		if(command_aura == "помощь")
			to_chat(src, span_notice("<br>Приказы дают ближайшим морпехам кратковременный бафф, за которым следует время восстановления, следующего вида:<br><B>Перемещение</B> - Повышенная мобильность и шанс уклониться от снарядов.<br><B>Удержание</B> - Повышенная устойчивость к боли и боевым ранениям.<br><B>Фокусировка</B> - Повышенная точность стрельбы и эффективная дальность.<br>"))
			return
		if(!command_aura)
			return

	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_SKILL_ORDERS))
		to_chat(src, span_warning("Вы недавно отдали приказ. Успокойтесь."))
		return

	if(!(command_aura in command_aura_allowed))
		return
	var/aura_strength = skills.getRating(SKILL_LEADERSHIP) - 1
	var/aura_target = pick_order_target()
	SSaura.add_emitter(aura_target, command_aura, aura_strength + 4, aura_strength, SKILL_ORDER_DURATION, faction)

	var/message = ""
	switch(command_aura)
		if("move")
			var/image/move = image('icons/mob/talk.dmi', src, icon_state = "order_move")
			message = pick("ПОПИЗДОВАЛИ!", "ВПЕРЁД, ВПЕРЁД, ВПЕРЁД!", "МЫ В ДВИЖЕНИИ!", "ДВИГАЕМ ЖОПАМИ!", "ВПЕРЁД!", "ДВИГАЕМСЯ-ДВИГАЕМСЯ-ДВИГАЕМСЯ!", "ВСТАВАЙТЕ НА НОГИ!", "ДВИГАЙТЕСЬ ВПЕРЁД!", "НА СВОИХ ДВОИХ!", "ВЫСТУПАЕМ!", "ПОШЛИТЕ, ПОШЛИТЕ!", "ВЫДВИГАЕМСЯ!", "УКАЗЫВАЮ ПУТЬ!", "ВПЕРЁД!", "НУ ЖЕ, ДВИГАЙТЕСЬ!", "БЫСТРЕЕ, ВПЕРЁД!")
			say(message)
			add_emote_overlay(move)
		if("hold")
			var/image/hold = image('icons/mob/talk.dmi', src, icon_state = "order_hold")
			message = pick("УКРОЙТЕСЬ И ПРИКРОЙТЕ!", "УДЕРЖИВАТЬ ЛИНИЮ!", "ДЕРЖАТЬ ПОЗИЦИИ!", "СТОЙТЕ НА СВОЕЙ ПОЗИЦИИ!", "ОСТАНОВИТЕСЬ И ОТСТРЕЛИВАЙТЕСЬ!", "УКРОЙТЕСЬ!", "ЗАЩИЩАЙТЕ ТЕРРИТОРИЮ!", "ПРИГОТОВЬТЕСЬ К УКРЫТИЮ!", "В УКРЫТИЕ!")
			say(message)
			add_emote_overlay(hold)
		if("focus")
			var/image/focus = image('icons/mob/talk.dmi', src, icon_state = "order_focus")
			message = pick("СФОКУСИРУЙТЕСЬ НА АТАКЕ!", "ЦЕЛЬТЕСЬ!", "ОРУЖИЕ НА ГОТОВЕ!", "ЦЕЛЬТЕСЬ!", "ЗАРЯЖАЙТЕ ОРУДИЯ!", "ГОТОВЬТЕСЬ К СТРЕЛЬБЕ!")
			say(message)
			add_emote_overlay(focus)

/datum/action/skill/issue_order/move
	name = "Выдать приказ о передислокации"

/datum/action/skill/issue_order/hold
	name = "Выдать приказ на удерживании точки"

/datum/action/skill/issue_order/focus
	name = "Выдать приказ о фокусировке"

// code/modules/screen_alert/command_alert.dm

/datum/action/innate/message_squad/action_activate()
	if(!can_use_action())
		return
	var/mob/living/carbon/human/human_owner = owner
	var/text = tgui_input_text(human_owner, "Максимальная длина сообщения [MAX_COMMAND_MESSAGE_LEN]", "Отправить сообщение отряду",  max_length = MAX_COMMAND_MESSAGE_LEN, multiline = TRUE)
	if(!text)
		return
	text = capitalize(text)
	var/filter_result = CAN_BYPASS_FILTER(human_owner) ? null : is_ic_filtered(text)
	if(filter_result)
		to_chat(human_owner, span_warning("В этом сообщении содержалось слово, запрещенное в IC чате! Рекомендуем ознакомиться с правилами сервера.\n<span replaceRegex='show_filtered_ic_chat'>\"[text]\"</span>"))
		SSblackbox.record_feedback(FEEDBACK_TALLY, "ic_blocked_words", 1, lowertext(config.ic_filter_regex.match))
		REPORT_CHAT_FILTER_TO_USER(src, filter_result)
		log_filter("IC", text, filter_result)
		return
	if(!can_use_action())
		return

	TIMER_COOLDOWN_START(owner, COOLDOWN_HUD_ORDER, CIC_ORDER_COOLDOWN)
	addtimer(CALLBACK(src, PROC_REF(update_button_icon)), CIC_ORDER_COOLDOWN + 1)
	update_button_icon()
	log_game("[key_name(human_owner)] has broadcasted the hud message [text] at [AREACOORD(human_owner)]")
	var/override_color
	var/list/alert_receivers
	var/sound_alert
	var/announcement_title

	if(human_owner.assigned_squad)
		alert_receivers = human_owner.assigned_squad.marines_list + GLOB.observer_list
		sound_alert = 'sound/effects/sos-morse-code.ogg'
		announcement_title = "Объявление Отряда [human_owner.assigned_squad.name]"
		switch(human_owner.assigned_squad.id)
			if(ALPHA_SQUAD)
				override_color = "red"
			if(BRAVO_SQUAD)
				override_color = "yellow"
			if(CHARLIE_SQUAD)
				override_color = "purple"
			if(DELTA_SQUAD)
				override_color = "blue"
			else
				override_color = "grey"
	else
		alert_receivers = GLOB.alive_human_list_faction[human_owner.faction] + GLOB.ai_list + GLOB.observer_list
		sound_alert = 'sound/misc/notice2.ogg'
		announcement_title = "Сообщение от [human_owner.job.title]"

	for(var/mob/mob_receiver in alert_receivers)
		mob_receiver.playsound_local(mob_receiver, sound_alert, 35, channel = CHANNEL_ANNOUNCEMENTS)
		mob_receiver.play_screen_text(HUD_ANNOUNCEMENT_FORMATTING(announcement_title, text, LEFT_ALIGN_TEXT), new /atom/movable/screen/text/screen_text/picture/potrait/custom_mugshot(null, null, owner), override_color)
		to_chat(mob_receiver, assemble_alert(
			title = announcement_title,
			subtitle = "Отправил [human_owner.get_paygrade(0) ? human_owner.get_paygrade(0) : human_owner.job.title] [human_owner.real_name]",
			message = text,
			color_override = override_color
		))

	var/list/tts_listeners = filter_tts_listeners(human_owner, alert_receivers, null, RADIO_TTS_COMMAND)
	if(!length(tts_listeners))
		return
	var/list/treated_message = human_owner?.treat_message(text) //we only treat the text here since it adds stutter to the text announcement otherwise
	var/list/extra_filters = list(TTS_FILTER_RADIO)
	if(isrobot(human_owner))
		extra_filters += TTS_FILTER_SILICON
	INVOKE_ASYNC(SStts, TYPE_PROC_REF(/datum/controller/subsystem/tts, queue_tts_message), human_owner, treated_message["tts_message"], human_owner.get_default_language(), human_owner.voice, human_owner.voice_filter, tts_listeners, FALSE, pitch = human_owner.pitch, special_filters = extra_filters.Join("|"), directionality = FALSE)

// code/game/atoms/atom_movable.dm

/atom/movable
	verb_say = "говорит"
	verb_ask = "спрашивает"
	verb_exclaim = "восклицает"
	verb_whisper = "шепчет"
	verb_sing = "воспевает"
	verb_yell = "кричит"

// code/modules/orbits/spaceship.dm

/obj/machinery/computer/navigation/do_orbit_checks(direction)
	var/current_orbit = GLOB.current_orbit

	if(!can_change_orbit(current_orbit, direction))
		return

	message_admins("[ADMIN_TPMONTY(usr)] Has sent the ship [direction == "UP" ? "UPWARD" : "DOWNWARD"] in orbit")

	var/message = "[usr.real_name] начал смену орбиты.\nПеремещаемся [direction == "UP" ? "вверх" : "вниз"] по гравитационной яме.\nНемедленно пристегните ремни безопасности и приготовьтесь к запуску двигателя через 10 секунд."
	minor_announce(message, title = "Смена Орбиты")
	addtimer(CALLBACK(src, PROC_REF(do_change_orbit), current_orbit, direction), 10 SECONDS)

/obj/machinery/computer/navigation/can_change_orbit(current_orbit, direction, silent = FALSE)
	if(changing_orbit)
		if(!silent)
			to_chat(usr, span_warning("В данный момент корабль меняет орбиту."))
		return FALSE
	if(direction == "UP" && current_orbit == HIGH_ORBIT)
		if(!silent)
			to_chat(usr, span_warning("Корабль находится на самой дальней орбите!"))
		return FALSE
	if(direction == "DOWN" && current_orbit == LOW_ORBIT)
		if(!silent)
			to_chat(usr, span_warning("Корабль находится слишком близко к [SSmapping.configs[GROUND_MAP].map_name]!"))
		return FALSE
	if(TIMER_COOLDOWN_RUNNING(src, COOLDOWN_ORBIT_CHANGE))
		if(!silent)
			to_chat(usr, span_warning("В данный момент корабль пересчитывает курс, основываясь на ранее выданой команде."))
		return FALSE
	return TRUE

/obj/machinery/computer/navigation/do_change_orbit(current_orbit, direction)

	//chug that sweet sweet powernet juice, like 80% of total
	if(powered()) //do we still have power?
		idle_power_usage = 5000
		addtimer(VARSET_CALLBACK(src, idle_power_usage, 10), 5 MINUTES)
	else
		return
	changing_orbit = TRUE
	engine_shudder()

	var/message = "Выход на новый орбитальный уровень. Немедленно пристегните ремни безопасности и приготовьтесь к запуску двигателей и стабилизации."
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(minor_announce), message, "Смена Орбиты"), 290 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(orbit_gets_changed), current_orbit, direction), 3 MINUTES)

/obj/machinery/computer/navigation/orbit_gets_changed(current_orbit, direction)
	if(direction == "UP")
		if(current_orbit == LOW_ORBIT)
			current_orbit = STANDARD_ORBIT
		else
			current_orbit = HIGH_ORBIT

	if(direction == "DOWN")
		if(current_orbit == HIGH_ORBIT)
			current_orbit = STANDARD_ORBIT
		else
			current_orbit = LOW_ORBIT

	GLOB.current_orbit = current_orbit
	changing_orbit = FALSE
	engine_shudder()

/obj/machinery/computer/navigation/engine_shudder()
	for(var/i in GLOB.alive_living_list) //knock down mobs
		var/mob/living/M = i
		if(!is_mainship_level(M.z))
			continue
		if(M.buckled)
			to_chat(M, span_warning("Вы испытываете сильный толчок напротив [M.buckled]!"))
			shake_camera(M, 3, 1)
		else
			to_chat(M, span_warning("Пол под ногами сотрясается!"))
			shake_camera(M, 10, 1)
			M.Knockdown(0.3 SECONDS)
		CHECK_TICK
