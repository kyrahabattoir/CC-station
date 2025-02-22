// SPDX-License-Identifier: CC-BY-NC-SA-3.0


/obj/item/storage/box/glassbox
	name = "glassware box"
	icon_state = "beaker"
	desc = "A box with glass cups for drinking liquids from."
	spawn_contents = list(/obj/item/reagent_containers/food/drinks/drinkingglass = 7)

/obj/item/storage/box/cutlery
	name = "cutlery set"
	icon_state = "donk_kit"
	desc = "Knives, forks, and spoons."
	spawn_contents = list(/obj/item/kitchen/utensil/fork = 2,\
	/obj/item/kitchen/utensil/knife = 2,\
	/obj/item/kitchen/utensil/spoon = 2)

/obj/item/storage/box/plates
	name = "dinnerware box"
	icon_state = "implant"
	desc = "A box with some plates and bowls."
	spawn_contents = list(/obj/item/plate = 4,\
	/obj/item/reagent_containers/food/drinks/bowl = 3)

/obj/item/storage/box/donkpocket_kit
	name = "\improper Donk-Pockets box"
	desc = "Remember to fully heat prior to serving.  Product will cool if not eaten within seven minutes."
	icon_state = "donk_kit"
	item_state = "box_red"
	spawn_contents = list(/obj/item/reagent_containers/food/snacks/donkpocket = 7)

/obj/item/storage/box/bacon_kit
	name = "bacon strips"
	desc = "A box of Farmer Jeff brand uncooked bacon strips."
	icon_state = "bacon"
	spawn_contents = list(/obj/item/reagent_containers/food/snacks/ingredient/meat/bacon/raw = 7)

/obj/item/storage/box/beer
	name = "beer in a box"
	icon_state = "beer"
	desc = "It's some beer, conveniently stored in a box! Dang!"
	spawn_contents = list(/obj/item/reagent_containers/food/drinks/bottle/fancy_beer = 6)

/obj/item/storage/box/cocktail_umbrellas
	name = "cocktail umbrella box"
	icon_state = "umbrellas"
	desc = "Ooh, little tiny umbrellas! Wow!"
	spawn_contents = list(/obj/item/cocktail_stuff/drink_umbrella = 7)

/obj/item/storage/box/cocktail_doodads
	name = "cocktail doodad box"
	icon_state = "doodads"
	desc = "Some neat stuff to put in fancy drinks. Woah!"
	spawn_contents = list(/obj/item/cocktail_stuff/maraschino_cherry = 2,\
	/obj/item/cocktail_stuff/cocktail_olive = 2,\
	/obj/item/cocktail_stuff/celery = 2)

/obj/item/storage/box/fruit_wedges
	name = "fruit wedge kit"
	icon_state = "wedges"
	desc = "All you need to make fruit wedges to put on drinks, for extra fanciness. Gosh!"
	spawn_contents = list(/obj/item/reagent_containers/food/snacks/plant/orange,\
	/obj/item/reagent_containers/food/snacks/plant/lemon,\
	/obj/item/reagent_containers/food/snacks/plant/lime,\
	/obj/item/kitchen/utensil/knife)

/obj/item/storage/goodybag
	name = "goodybag"
	desc = "A bag designed to store Halloween candy."
	icon_state = "goodybag"

	make_my_stuff()
		..()
		var/list/candytypes = typesof(/obj/item/reagent_containers/food/snacks/candy)
		for (var/i=6, i>0, i--)
			var/newcandy_path = pick(candytypes)
			var/obj/item/reagent_containers/food/snacks/candy/newcandy = new newcandy_path(src)
			if (prob(5))
				newcandy.razor_blade = 1
