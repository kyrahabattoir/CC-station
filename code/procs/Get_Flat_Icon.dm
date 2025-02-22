// SPDX-License-Identifier: CC-BY-NC-SA-3.0


/* *********************************************************************
        _____      _     ______ _       _     _____
       / ____|    | |   |  ____| |     | |   |_   _|
      | |  __  ___| |_  | |__  | | __ _| |_    | |  ___ ___  _ __
      | | |_ |/ _ \ __| |  __| | |/ _` | __|   | | / __/ _ \| '_ \
      | |__| |  __/ |_  | |    | | (_| | |_   _| || (_| (_) | | | |
       \_____|\___|\__| |_|    |_|\__,_|\__| |_____\___\___/|_| |_|

                Created by David "DarkCampainger" Braun

             Released under the Unlicense (see end of file)

                   Version 3.0 - September 19, 2014

*///////////////////////////////////////////////////////////////////////


// Associative list of [md5 values = Icon] for determining if the icon already exists
var/list/_flatIcons = list()

proc
	getFlatIcon(atom/A, dir, cache=1) // 1 = use cache, 2 = override cache, 0 = ignore cache

		var/list/layers = list() // Associative list of [overlay = layer]
		var/hash = "" // Hash of overlay combination

		if(!dir) dir = A.dir // dir defaults to A's dir

		var/parentColor = ""
		if(A.color || A.alpha != 255)
			parentColor = (A.color || "#FFFFFF") + copytext(rgb(0,0,0,A.alpha), 8)

		// Add the atom's icon itself
		if(A.icon)
			// Make a copy without pixel_x/y settings
			var/image/copy = image(icon=A.icon,icon_state=A.icon_state,layer=A.layer,dir=dir)
			layers[copy] = A.layer

		// Loop through the underlays, then overlays, sorting them into the layers list
		var
			list/process = A.underlays // Current list being processed
			processSubset=0 // Which list is being processed: 0 = underlays, 1 = overlays

			currentIndex=1 // index of 'current' in list being processed
			currentOverlay // Current overlay being sorted
			currentLayer // Calculated layer that overlay appears on (special case for FLOAT_LAYER)

			compareOverlay // The overlay that the current overlay is being compared against
			compareIndex // The index in the layers list of 'compare'
		while(TRUE)
			if(currentIndex<=process.len)
				currentOverlay = process[currentIndex]
				currentLayer = currentOverlay:layer
				if(currentLayer<0) // Special case for FLY_LAYER
					ASSERT(currentLayer > -1000)
					if(processSubset == 0) // Underlay
						currentLayer = A.layer+currentLayer/1000
					else // Overlay
						currentLayer = A.layer+(1000+currentLayer)/1000

				// Sort add into layers list
				for(compareIndex=1,compareIndex<=layers.len,compareIndex++)
					compareOverlay = layers[compareIndex]
					if(currentLayer < layers[compareOverlay]) // Associated value is the calculated layer
						layers.Insert(compareIndex,currentOverlay)
						layers[currentOverlay] = currentLayer
						break
				if(compareIndex>layers.len) // Reached end of list without inserting
					layers[currentOverlay]=currentLayer // Place at end

				currentIndex++

			if(currentIndex>process.len)
				if(processSubset == 0) // Switch to overlays
					currentIndex = 1
					processSubset = 1
					process = A.overlays
				else // All done
					break

		if(cache!=0) // If cache is NOT disabled
			// Create a hash value to represent this specific flattened icon
			hash = "[parentColor];__;"
			for(var/I in layers)
				hash += "\ref[I:icon],[I:icon_state],[I:dir != SOUTH ? I:dir : dir],[I:pixel_x],[I:pixel_y],[I:color],[I:alpha];_;"
			hash=md5(hash)

			if(cache!=2) // If NOT overriding cache
				// Check if the icon has already been generated
				if((hash in _flatIcons) && _flatIcons[hash])
					// Icon already exists, just return that one
					return _flatIcons[hash]

		var
			// We start with a blank canvas, otherwise some icon procs crash silently
			icon/flat = icon('icons/misc/flatBlank.dmi') // Final flattened icon
			icon/add // Icon of overlay being added

			// Set current dimensions of flattened icon
			flatX1=1
			flatX2=flat.Width()
			flatY1=1
			flatY2=flat.Height()

			// Dimensions of overlay being added
			addX1;addX2;addY1;addY2

		for(var/I in layers)

			add = icon(I:icon || A.icon
			         , I:icon_state || (I:icon && (A.icon_state in icon_states(I:icon)) && A.icon_state)
			         , (I:dir != SOUTH ? I:dir : dir)
			         , 1
			         , 0)

			// Apply any color or alpha settings
			if(I:color || I:alpha != 255)
				var/rgba = (I:color || "#FFFFFF") + copytext(rgb(0,0,0,I:alpha), 8)
				add.Blend(rgba, ICON_MULTIPLY)

			if(parentColor)
				add.Blend(parentColor, ICON_MULTIPLY)

			// Find the new dimensions of the flat icon to fit the added overlay
			addX1 = min(flatX1, I:pixel_x+1)
			addX2 = max(flatX2, I:pixel_x+add.Width())
			addY1 = min(flatY1, I:pixel_y+1)
			addY2 = max(flatY2, I:pixel_y+add.Height())

			if(addX1!=flatX1 || addX2!=flatX2 || addY1!=flatY1 || addY2!=flatY2)
				// Resize the flattened icon so the new icon fits
				flat.Crop(addX1-flatX1+1, addY1-flatY1+1, addX2-flatX1+1, addY2-flatY1+1)
				flatX1=addX1;flatX2=addX2
				flatY1=addY1;flatY2=addY2

			// Blend the overlay into the flattened icon
			flat.Blend(add,ICON_OVERLAY,I:pixel_x+2-flatX1,I:pixel_y+2-flatY1)

		if(cache!=0) // If cache is NOT disabled
			// Cache the generated icon in our list so we don't have to regenerate it
			_flatIcons[hash] = flat

		return flat

/* License:
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
*/