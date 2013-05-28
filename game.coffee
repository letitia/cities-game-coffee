GAME.curr_letter = ""
GAME.curr_city = []
GAME.used_citynames = []
GAME.used_countries = {}
GAME.error = ""
GAME.alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
GAME.special_chars = {
        "a": ['\xe0', '\xe1', '\xe2', '\xe3', '\xe4', '\xe5', '\xc2',], #['ä', 'â', 'å', 'ã', 'á', 'à', 'Â'],
        "e": ['\xe8', '\xe9', '\xea'],                                  #["è", "é", "ê""],
        "i": ['\xed'],                                                  #['í'],
        "o": ['\xf3', '\xf4', '\xf5', '\xf6', '\xf8'],                  #["ó", "ô", "õ", "ö", "ø"],
        "u": ['\xfa', '\xfc']                                           #['ú', 'ü'],
        "c": ['\xe7'],                                                  #['ç'],
        "d": ['\xf0'],                                                  #["ð"]
        "n": ['\xf1'],                                                  #['ñ'],
        "s": ['\x9a'],                                                  #['š'],
        "ss": ['\xdf'],                                                 #['ß'],
        ".": [" ", "-", ";", ""],
        " ": ["'", "-", ";", ""],
        "-": [" ", "'", ";", ""],
        "'": [" ", "-", ";", ""],
        ";": [" ", "'", "-", ""]
    }
GAME.busy = false


window.handleInputKeyup = (evt) ->
	handleSubmit() if evt.keyCode is 13

window.handleSubmit = () ->
	#setBusy()
	cityname = $.trim($('input[name=city_name]').val())
	answerIsValid = cityname and currLetterStartsCityname(cityname) and isValidCity(cityname) and currCityNeverUsed()
	#setNotBusy()
	updateProgramAndDisplay(answerIsValid)
	handleComputerTurn()
	
currLetterStartsCityname = (city) ->
	if curr_letter
		if not (city[0].toUpperCase() is curr_letter)
			GAME.error = "The first letter of your city must start with " + curr_letter
			return false
	true
		
isValidCity = (input_cityname) ->
	input_cityname = input_cityname.toLowerCase()
	first_letter = (input_cityname[0]).toUpperCase()
	city = first_letter + input_cityname.substr(1)

	if not (first_letter of cities)
		GAME.error = "The first letter of your city is not in the English alphabet."
		return false

	city_dict_starting_with = cities[first_letter]

	if input_cityname of city_dict_starting_with
		acknowledgeInputCity(input_cityname, city_dict_starting_with)
		return true

	close_names = generateCloseWordList(input_cityname)
	for name in close_names
		if name of city_dict_starting_with
			acknowledgeInputCity(name, city_dict_starting_with)
			return true
	GAME.error = input_cityname + " is NOT a valid city."
	false

acknowledgeInputCity = (name, dict) ->
	country_id = dict[name][0]	#FIXME:  for now, only take first country in list
	display_name = name.toProperCase()
	GAME.curr_city = [display_name, country_id]
	$('input[name=city_name]').val('')

generateCloseWordList = (word) ->
	word = word.toLowerCase()
	edit_dist = getEditDistance(word)
	
	wordlist = []
	generateEditDistanceList(word, edit_dist, wordlist)
	wordlist

generateEditDistanceList = (word, edit_dist, wordlist) ->
	if edit_dist is 0 then return

	# replace every letter except first letter
	for letter, i in word when i > 0
		if letter of special_chars
			replacements = special_chars[letter]
			for rep in replacements
				replaced = word[...i] + rep + word[i+1...]
				wordlist.push(replaced)
				generateEditDistanceList(replaced, edit_dist - 1, wordlist)

currCityNeverUsed = () ->
	unused = true
	curr_cityname = curr_city[0]
	if curr_cityname in used_citynames
		GAME.error = "You've used that city already!"
		unused = false
	unused

getEditDistance = (word) ->
	len = word.length
	if len < 3  then return 1
	if len < 11 then return 2
	if len < 15 then return 3
	4

updateProgramAndDisplay = (cityIsValid) ->
	if cityIsValid
		updateWithNewCity()
	else
		handleErrors()
	$('.usedcities').text used_citynames
	$('.count').text used_citynames.length
	printCountries()
	return

updateWithNewCity = ->
	curr_cityname = curr_city[0]
	curr_country = curr_city[1]
	$('.status').text "You got it!  #{curr_cityname} is in #{countries[curr_country]}"
	GAME.curr_city = []
	used_citynames.push curr_cityname
	incrementKeyFrequencyInMap(curr_country, used_countries)

	addCityTile(curr_cityname)

	GAME.curr_letter = curr_cityname[-1..].toUpperCase()
	$('.currletter').text curr_letter

addCityTile = (cityname) ->
	tile = $('<div class="city" />')
	tile.text cityname

	# get image
	$.get "http://en.wikipedia.org/w/api.php?action=query&titles=#{formatNameForWikipedia(cityname)}&format=json&prop=images&imlimit=1"

	# get wiki text
	$.get "http://en.wikipedia.org/w/api.php?action=query&titles=#{formatNameForWikipedia(cityname)}&format=json&prop=revisions&rvprop=content"
	
	$('#content').prepend tile

printCountries = () ->
	result = ""
	for id, count of used_countries
		result += "#{countries[id]}: #{count}<br />"
	$('.countries').html result

formatNameForWikipedia = (cityname) ->
	# upper case and escape everything with underscore,
	# e.g. San_Francisco, Port_Au_Prince, Sault_Ste_Marie, Sault_Sainte_Marie


handleComputerTurn = (valid) ->
	setTimeout computerTurn, 1000 if valid
	

computerTurn = ->
	$('.status').text "Computer's turn..."

handleErrors = ->
	$('.status').text error

incrementKeyFrequencyInMap = (key, map) ->
	if not (key of map) then map[key] = 0
	map[key] += 1

checkBusyStatus = ->
	setInterval (() -> if busy then $('#spinner').show() else $('#spinner').hide()), 10

setBusy = ->
	$('#spinner').show()

setNotBusy = ->
	$('#spinner').hide()


#checkBusyStatus();



#  T E S T S

# This takes a couple of minutes, or longer if you uncomment out the long cases
window.runTestCases = () ->
	"""testWordsDontMatch('LA', 'Lazdijai', 2)
	testWordsMatch('Claremont', 'Claremont', 2)
	testWordsDontMatch('Clearmont', 'Claremont', 2)
	testWordsDontMatch('Upton', 'Unity', 2)
	"""
	
	$('.testresults').append $('<br />')
	testCityIsValid('Stanford')
	#testCityIsInvalid('Pirateville')			# this test takes 30 seconds
	testCityIsValid('dubai')
	testCityIsValid('Port-au-prince')
	testCityIsValid('Sault Ste-Marie')
	#testCityIsValid('Sault Sainte-Marie')		# this test takes a few minutes.  will fail unless we do edit distance
	testCityIsValid('Belem')		
	testCityIsValid('Port au prince')
	

testWordsMatch = (input, city, edit_dist) ->
	passed = wordsMatchWithinEditDistance input, city, edit_dist
	$result = $('<div />').text "Testing that " + input + " and " + city + " match within " + edit_dist + " ... " + resultText(passed)
	$result.css('color', resultColor(passed))
	$('.testresults').append $result

testWordsDontMatch = (input, city, edit_dist) ->
	passed = not wordsMatchWithinEditDistance input, city, edit_dist
	$result = $('<div />').text "Testing that " + input + " and " + city + " do NOT match within " + edit_dist + " ... " + resultText(passed)
	$result.css('color', resultColor(passed))
	$('.testresults').append $result

testCityIsValid = (cityname) ->
	passed = isValidCity cityname
	$result = $('<div />').text "Testing that " + cityname + " is valid ... " + resultText(passed)
	$result.css('color', resultColor(passed))
	$('.testresults').append $result

testCityIsInvalid = (cityname) ->
	passed = not isValidCity cityname
	$result = $('<div />').text "Testing that " + cityname + " is NOT valid ... " + resultText(passed)
	$result.css('color', resultColor(passed))
	$('.testresults').append $result

resultText = (passed) ->
	if passed then 'Passed' else 'Failed'
	
resultColor = (passed) ->
	if passed then 'green' else 'red'



# Utilities

String.prototype.toProperCase = () ->
    this.replace /\w\S*/g, (txt) -> txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

