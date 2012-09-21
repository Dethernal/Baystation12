//This file was auto-corrected by findeclaration.exe on 29/05/2012 15:03:05

/obj/item/weapon/storage/lockbox
	name = "lockbox"
	desc = "A locked box."
	icon_state = "lockbox+l"
	item_state = "syringe_kit"
	w_class = 4
	max_w_class = 3
	max_combined_w_class = 14 //The sum of the w_classes of all the items in this storage item.
	storage_slots = 4
	req_access = list(ACCESS_ARMORY)
	var/locked = 1
	var/broken = 0
	var/icon_locked = "lockbox+l"
	var/icon_closed = "lockbox"
	var/icon_broken = "lockbox+b"
	var/hack = 0
	var/list/signalers[5]
	var/lockboxWiresCutted = list(0, 0, 0, 0, 0)
	var/lockboxIndexToWireColor = list(0, 0, 0, 0, 0)
	var/lockboxWireColorToIndex = list(0, 0, 0, 0, 0)
	var/list/wire_index = list(
			"Orange" = 1,
			"Dark red" = 2,
			"White" = 3,
			"Yellow" = 4,
			"Red" = 5
		)

	proc/RandomizeColors()
		for (var/i = 1; i<=5;i+=1)
			var/j = rand(1,5)
			while (lockboxWireColorToIndex[j])
				j = rand(1,5)
			lockboxIndexToWireColor[i] = j
			lockboxWireColorToIndex[j] = i

	New()
		..()
		RandomizeColors()
		return

	proc/HasSignalers()
		for (var/i=1;i<=5;i+=1)
			if(signalers[i])
				return 1
		return 0

	proc/SelfDestruct()
		for (var/obj/O in src)
			if (istype(O, /obj/item/weapon/disk/nuclear))
				O.loc = get_turf(src)
			else
				del(O)
		explosion(get_turf(src),-1,-1,1)
		del(src)
		return



	attack_hand(mob/user as mob)
		if(!hack)
			..(user)
			return
		var/t1 = text("<B>Wires</B><br>\n")
		t1 += Wires()
		t1 += text("<p><a href='?src=\ref[];close=1'>Close</a></p>\n", src)
		user << browse(t1, "window=lockbox")
		onclose(user, "lockbox")

	proc/Wires(var/wirenum)
		var/t1
		var/iterator = 0
		for(var/wiredesc in wire_index)
			if(iterator == wirenum)
				break
			var/is_uncut = !lockboxWiresCutted[lockboxWireColorToIndex[wire_index[wiredesc]]]
			t1 += "[wiredesc] wire: "
			if(!is_uncut)
				t1 += "<a href='?src=\ref[src];wires=[wire_index[wiredesc]]'>Mend</a>"
			else
				t1 += "<a href='?src=\ref[src];wires=[wire_index[wiredesc]]'>Cut</a> "
				t1 += "<a href='?src=\ref[src];pulse=[wire_index[wiredesc]]'>Pulse</a> "
				if(src.signalers[wire_index[wiredesc]])
					t1 += "<a href='?src=\ref[src];remove-signaler=[wire_index[wiredesc]]'>Detach signaler</a>"
				else
					t1 += "<a href='?src=\ref[src];signaler=[wire_index[wiredesc]]'>Attach signaler</a>"
			t1 += "<br>"
			iterator++
		return t1


	proc/isWireColorCut(var/i)
		return lockboxWiresCutted[lockboxWireColorToIndex[i]]

	Topic(href, href_list, var/nowindow = 0)
		if(!nowindow)
			..()
		if(usr.stat || usr.restrained())
			return
		if(href_list["close"])
			usr << browse(null, "window=lockbox")
			if(usr.machine==src)
				usr.machine = null
				return

		usr.machine = src
		if(href_list["wires"])
			var/t1 = text2num(href_list["wires"])
			if(!( istype(usr.equipped(), /obj/item/weapon/wirecutters) || istype(usr.equipped(),/obj/item/weapon/shard)))
				usr << "You need wirecutters!"
				return
			if(src.isWireColorCut(t1) && istype(usr.equipped(), /obj/item/weapon/wirecutters))
				src.mend(t1, usr)
			else
				src.cut(t1, usr)
		else if(href_list["pulse"])
			var/t1 = text2num(href_list["pulse"])
			if(!istype(usr.equipped(), /obj/item/device/multitool))
				usr << "You need a multitool!"
				return
			if(src.isWireColorCut(t1))
				usr << "You can't pulse a cut wire."
				return
			else
				src.pulse(t1)
		else if(href_list["signaler"])
			var/wirenum = text2num(href_list["signaler"])
			if(!istype(usr.equipped(), /obj/item/device/assembly/signaler))
				usr << "You need a signaller!"
				return
			if(src.isWireColorCut(wirenum))
				usr << "You can't attach a signaller to a cut wire."
				return
			var/obj/item/device/assembly/signaler/R = usr.equipped()
			if(R.secured)
				usr << "This radio can't be attached!"
				return
			var/mob/M = usr
			M.drop_item()
			R.loc = src
			R.airlock_wire = wirenum
			src.signalers[wirenum] = R
		else if(href_list["remove-signaler"])
			var/wirenum = text2num(href_list["remove-signaler"])
			if(!(src.signalers[wirenum]))
				usr << "There's no signaller attached to that wire!"
				return
			var/obj/item/device/assembly/signaler/R = src.signalers[wirenum]
			R.loc = usr.loc
			R.airlock_wire = null
			src.signalers[wirenum] = null

		src.update_icon()
		src.updateUsrDialog()


	proc/cut(var/wireColor, mob/user as mob)
		var/wireIndex = lockboxWireColorToIndex[wireColor]
		if (!istype(user, /mob/living/carbon/human))
			return
		var/mob/living/carbon/human/H = user
		lockboxWiresCutted[wireIndex] = 1
		if (wireColor<3)
			return
		if(lockboxWiresCutted[3] & lockboxWiresCutted[4] & lockboxWiresCutted[5])
			if((istype(H.l_ear, /obj/item/device/radio/headset) && H.l_ear:on == 1) || (istype(H.r_ear, /obj/item/device/radio/headset) && H.r_ear:on == 1))
				H << "You hear quiet crackling sound in your radio."

	proc/mend(var/wireColor, mob/user as mob)
		var/wireIndex = lockboxWireColorToIndex[wireColor]
		if (!istype(user, /mob/living/carbon/human))
			return
		lockboxWiresCutted[wireIndex] = 0

	proc/pulse(var/wireColor)
		var/obj/item/device/radio/b = new /obj/item/device/radio(null)
		b.config(list("Security" = 0))
		b.autosay("\"DEBUG [wireColor]\"", "Scecial equipment computer", "department")
		del(b)
		var/wireIndex = lockboxWireColorToIndex[wireColor]
		if (src.lockboxWiresCutted[wireIndex])
			return
		switch(wireIndex)
			if(1)
				SelfDestruct()
				return
			if(2)
				src.locked = 0
				return
			if (3,4,5)
				var/obj/item/device/radio/a = new /obj/item/device/radio(null)
				a.config(list("Security" = 0))
				a.autosay("\"Warning!  Unautorized acsess to [src.name] in [get_area(src.loc)] \"", "Scecial equipment computer", "department")
				del(a)


	attackby(obj/item/weapon/W as obj, mob/user as mob)
		if (istype(W, /obj/item/weapon/screwdriver))
			if(src.broken)
				user << "\red It appears to be broken."
				return

			if (src.hack)
				if(HasSignalers())
					user << "Cover not fit."
					return
			src.hack = !hack
			if (src.hack)
				src.icon_state = src.icon_broken
				src.update_icon()
				return
			else
				if(src.locked)
					src.icon_state = src.icon_locked
				else
					src.icon_state = icon_closed
				src.update_icon()
			return



		if (istype(W, /obj/item/weapon/card/id))
			if(src.broken)
				user << "\red It appears to be broken."
				return
			if(src.allowed(user))
				src.locked = !( src.locked )
				if(src.locked)
					src.icon_state = src.icon_locked
					user << "\red You lock the [src.name]!"
					return
				else
					src.icon_state = src.icon_closed
					user << "\red You unlock the [src.name]!"
					return
			else
				user << "\red Access Denied"
		else if((istype(W, /obj/item/weapon/card/emag)||istype(W, /obj/item/weapon/melee/energy/blade)) && !src.broken)
			if(istype(W, /obj/item/weapon/card/emag))
				var/obj/item/weapon/card/emag/E = W
				if(E.uses)
					E.uses--
				else
					return
			broken = 1
			locked = 0
			desc = "It appears to be broken."
			icon_state = src.icon_broken
			if(istype(W, /obj/item/weapon/melee/energy/blade))
				var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
				spark_system.set_up(5, 0, src.loc)
				spark_system.start()
				playsound(src.loc, 'blade1.ogg', 50, 1)
				playsound(src.loc, "sparks", 50, 1)
				for(var/mob/O in viewers(user, 3))
					O.show_message(text("\blue The locker has been sliced open by [] with an energy blade!", user), 1, text("\red You hear metal being sliced and sparks flying."), 2)
			else
				for(var/mob/O in viewers(user, 3))
					O.show_message(text("\blue The locker has been broken by [] with an electromagnetic card!", user), 1, text("You hear a faint electrical spark."), 2)

		if(!locked)
			..()
		else
			user << "\red Its locked!"
		return


	show_to(mob/user as mob)
		if (hack)
			user << "\red Cover is open!"
		else
			if(locked)
				user << "\red Its locked!"
			else
				..()
		return


/obj/item/weapon/storage/lockbox/loyalty
	name = "Lockbox (Loyalty Implants)"
	req_access = list(ACCESS_SECURITY)

	New()
		..()
		new /obj/item/weapon/implantcase/loyalty(src)
		new /obj/item/weapon/implantcase/loyalty(src)
		new /obj/item/weapon/implantcase/loyalty(src)
		new /obj/item/weapon/implanter/loyalty(src)


/obj/item/weapon/storage/lockbox/clusterbang
	name = "lockbox (clusterbang)"
	desc = "You have a bad feeling about opening this."
	req_access = list(ACCESS_SECURITY)

	New()
		..()
		new /obj/item/weapon/flashbang/clusterbang(src)
