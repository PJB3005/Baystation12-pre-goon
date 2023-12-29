/var/const/OPEN = 1
/var/const/CLOSED = 2

/obj/machinery/door/firedoor/open()
	usr << "This is a remote firedoor!"
	return

/obj/machinery/door/firedoor/close()
	usr << "This is a remote firedoor!"
	return

/obj/machinery/door/firedoor/power_change()
	if( powered(ENVIRON) )
		stat &= ~NOPOWER
	else
		stat |= NOPOWER

/obj/machinery/door/firedoor/Bumped(atom/movable/AM as mob|obj)
	return

/obj/machinery/door/firedoor/attackby(obj/item/weapon/C as obj, mob/user as mob)
	src.add_fingerprint(user)
	if ((istype(C, /obj/item/weapon/weldingtool) && !( src.operating ) && src.density) && !src.hulksmash)
		var/obj/item/weapon/weldingtool/W = C
		if(W.welding)
			if (W.weldfuel > 2)
				W.weldfuel -= 2
			if (!( src.blocked ))
				src.blocked = 1
				src.icon_state = "firedoorl"
			else
				src.blocked = 0
				src.icon_state = "firedoor1"
			return
	if (!( istype(C, /obj/item/weapon/crowbar) ))
		return

	if (!src.blocked && !src.operating && !src.hulksmash)
		if(src.density)
			spawn( 0 )
				src.operating = 1
				flick("firedoorc0", src)
				src.icon_state = "firedoor0"
				sleep(15)
				src.density = 0
				sd_SetOpacity(0)
				var/turf/T = src.loc
				if (istype(T, /turf) && checkForMultipleDoors())
					T.updatecell = 1
					OpenDoor(src)
				src.operating = 0
				return
		else //close it up again
			spawn( 0 )
				src.operating = 1
				flick("firedoorc1", src)
				src.icon_state = "firedoor1"
				sleep(15)
				src.density = 1
				sd_SetOpacity(1)
				var/turf/T = src.loc
				if (istype(T, /turf))
					T.updatecell = 0
					CloseDoor(src)
				src.operating = 0
				return
	return
/obj/machinery/door/firedoor/attack_hand(mob/user as mob)
	if (usr.ishulk)
		var/B = pick(1,2,3,4,5,6)
		src.hear_sound("sound/damage/wall/impact[B].wav",6)
		if (prob(25))
			src.icon_state = "firedoor1_hulk"
			user << "You punch through the door!"
			src.density = 0
			src.operating = 0
			sd_SetOpacity(0)
			OpenDoor(src)
			src.hulksmash = 1
		else
			user << "You punch the door!"
	if(usr.zombie)
		var/B = pick(1,2,3,4,5,6)
		var/atkdmg = 4
		src.hear_sound("sound/damage/wall/impact[B].wav",6)
		for(var/mob/O in range(3,src)) // when zombie's swarm, they do more damage.
			if (O.zombie)
				atkdmg += 4
		src.hitpoints -= atkdmg
		if (src.hitpoints <= 0)
			src.icon_state = "firedoor1_hulk"
			user << "You claw through the door!"
			src.density = 0
			src.operating = 0
			sd_SetOpacity(0)
			src.hulksmash = 1
			sd_SetOpacity(0)
			var/turf/T = src.loc
			if (istype(T, /turf) && checkForMultipleDoors())
				T.updatecell = 1
				OpenDoor(src)
		else
			user << "You claw the door!"

/obj/machinery/door/firedoor/proc/openfire()
	set src in oview(1)

	if (src.hulksmash)
		return

	if(stat & (NOPOWER|BROKEN))
		return

	if((src.operating || src.blocked))
		return
	use_power(50, ENVIRON)
	src.operating = 1
	src.hear_sound("sound/door/airlock/move.wav",5)
	flick("firedoorc0", src)
	src.icon_state = "firedoor0"
	sleep(15)
	src.density = 0
	sd_SetOpacity(0)
	var/turf/T = src.loc
	if (istype(T, /turf) && checkForMultipleDoors())
		T.updatecell = 1
		OpenDoor(src)
	src.operating = 0
	return

/obj/machinery/door/firedoor/proc/closefire()
	set src in oview(1)

	if (src.hulksmash)
		return

	if(stat & (NOPOWER|BROKEN))
		return

	if(src.operating)
		return
	use_power(50, ENVIRON)
	src.operating = 1
	flick("firedoorc1", src)
	src.hear_sound("sound/door/airlock/move.wav",5)
	src.icon_state = "firedoor1"
	src.density = 1
	sd_SetOpacity(1)
	var/turf/T = src.loc
	if (istype(T, /turf))
		T.updatecell = 0
		CloseDoor(src)
		T.firelevel = 0
	sleep(15)
	src.operating = 0
	return

/obj/machinery/door/firedoor/process()
	if (src.hulksmash)
		var/B = pick(1,2,3,4,5,6)
		src.hear_sound("sound/enviroment/spark/spark[B].wav",3)
	if(src.operating)
		return
	if(src.nextstate)
		if(src.nextstate == OPEN && src.density)
			spawn()
				src.openfire()
		else if(src.nextstate == CLOSED && !src.density)
			spawn()
				src.closefire()
		src.nextstate = null