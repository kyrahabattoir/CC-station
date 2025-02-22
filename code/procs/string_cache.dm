// SPDX-License-Identifier: CC-BY-NC-SA-3.0

var/global/list/string_cache

/proc/strings(filename as text, key as text, var/accept_absent = 0)
	var/list/fileList
	if(!string_cache)
		string_cache = new
	if(!(filename in string_cache))
		if(fexists("strings/[filename]"))
			string_cache[filename] = list()
			var/list/stringsList = list()
			fileList = dd_file2list("strings/[filename]")
			var/lineCount = 0
			for(var/s in fileList)
				lineCount++
				if (!s)
					continue

				stringsList = splittext(s, "@=")
				if(stringsList.len != 2)
					CRASH("Invalid string list in strings/[filename] - line: [lineCount]")
				if(findtext(stringsList[2], "@,"))
					string_cache[filename][stringsList[1]] = splittext(stringsList[2], "@,")
				else
					string_cache[filename][stringsList[1]] = stringsList[2] // Its a single string!
		else
			CRASH("file not found: strings/[filename]")
	if((filename in string_cache) && (key in string_cache[filename]))
		return string_cache[filename][key]
	else if (accept_absent) //Don't crash, just return null. It's fine. Honest
		return null
	else
		CRASH("strings list not found: strings/[filename], index=[key]")