
/datum/looping_sound/dmusloop
	mid_sounds = list()
	mid_length = 12000 // 20 minutes to force a loop. File size determines server load, not audio length. Low bitrate .ogg files can run long and have their uses as ambient sound.
	volume = 100
	falloff = 2
	extra_range = 10	// Up from 5, fill a room.
	var/stress2give = /datum/stressevent/music
	persistent_loop = TRUE
	channel = CHANNEL_CMUSIC

/datum/looping_sound/dmusloop/on_hear_sound(mob/M)
	. = ..()
	if(stress2give)
		if(isliving(M))
			var/mob/living/carbon/L = M
			L.add_stress(stress2give)

/obj/item/dmusicbox
	name = "dwarven music box"
	desc = "It is essential that the deepest caves be tuned to the right frequency of vibrations."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "mbox0"
	gripped_intents = list(INTENT_GENERIC)
	w_class = WEIGHT_CLASS_HUGE
	twohands_required = TRUE
	force = 20
	throwforce = 20
	throw_range = 2
	var/datum/looping_sound/dmusloop/soundloop
	var/curfile
	var/playing = FALSE
	var/loaded = TRUE
	var/lastfilechange = 0
	var/curvol = 100
	anvilrepair = /datum/skill/craft/blacksmithing

/obj/item/dmusicbox/Initialize()
	soundloop = new(src, FALSE)
//	soundloop.start()
	update_icon()
	. = ..()

/obj/item/dmusicbox/update_icon()
	if(playing)
		icon_state = "mboxon"
	else
		icon_state = "mbox[loaded]"

/obj/item/dmusicbox/attackby(obj/item/P, mob/user, params)
	if(!loaded)
		if(istype(P, /obj/item/roguecoin/copper))
			loaded=TRUE
			qdel(P)
			update_icon()
			playsound(loc, 'sound/misc/machinevomit.ogg', 100, TRUE, -1)
			return
	. = ..()

/obj/item/dmusicbox/rmb_self(mob/user)
	attack_right(user)
	return

/obj/item/dmusicbox/attack_right(mob/user)
	. = ..()
	if(.)
		return
	if(loc != user)
		return
	if(!user.ckey)
		return
	if(playing)
		return
	user.changeNext_move(CLICK_CD_MELEE)
	if(lastfilechange)
		if(world.time < lastfilechange + 3 MINUTES)
			say("NOT YET!")
			return
	if(!loaded)
		say("ONE COIN, A COPPER COIN FOR AN AFTERNOON OF JOY!")
		return
	playsound(loc, 'sound/misc/beep.ogg', 100, FALSE, -1)
	var/infile = input(user, "CHOOSE A NEW SONG", src) as null|file

	if(!infile)
		return

	if(!loaded)
		return

	var/filename = "[infile]"
	var/file_ext = lowertext(copytext(filename, -4))
	var/file_size = length(infile)

	if(file_ext != ".ogg")
		to_chat(user, span_warning("SONG MUST BE AN OGG."))
		return
	if(file_size > 6485760)
		to_chat(user, span_warning("TOO BIG. 6 MEGS OR LESS."))
		return
	lastfilechange = world.time
	fcopy(infile,"data/jukeboxuploads/[user.ckey]/[filename]")
	curfile = file("data/jukeboxuploads/[user.ckey]/[filename]")

	loaded = FALSE
	update_icon()


/obj/item/dmusicbox/attack_self(mob/living/user)
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE)
	playsound(loc, 'sound/misc/beep.ogg', 100, FALSE, -1)
	if(!playing)
		if(curfile)
			playing = TRUE
			soundloop.mid_sounds = list(curfile)
			soundloop.cursound = null
			soundloop.start()
	else
		playing = FALSE
		soundloop.stop()
	update_icon()
