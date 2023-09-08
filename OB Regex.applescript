-- <export location>Script Libraries Folder</export location>
-- <export format>Compiled Script</export format>
-- OB Regex
--	Created by: Nicholas Parsons
--	Created on: 9/9/2023
--
--	Copyright © 2023 Nicholas Parsons, All Rights Reserved
--

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "RegexAndStuffLib" version "1.0.6"
use OBUtility : script "OB Utilities" version "1.14"

property name : "OB Regex"
property version : "1.0"
property id : "com.openbooksapp.ob-regex"

on extractPostCodeFrom(thisAddress)
	doOBLog of OBUtility for "Extracting post code (and possibly country) from " & thisAddress given logType:"debug"
	-- first search for a post code and, if it's found, break the string into 3 parts: the string leading up to the post code, the post code, and the string trailing the post code
	-- #todo: Currently will treat any number 4 digits or longer as a post code. Could specify that there needs to be some non digit character following the string of 4/5 digits in order for it to be recognised as a post code but then that might not detect a post code that is at the end of the string.
	-- was: "(^.*)\\s(\\d{4,5})\\W+[^a-z]*([a-z]*).*$"
	set theResult to regex search thisAddress search pattern "(^.*)\\s(\\d{4,5})\\W*(\\D*).*$" capture groups {} with dot matches all without anchors match lines
	if theResult is {} then -- no post code was detected
		set postcode to ""
		set theCountry to ""
	else -- a post code was detected
		set theResult to the last item of theResult
		set postcode to item 3 of theResult
		-- but it's possible that instead of a post code we might have just detected a unit number or street number at the beginning of the address
		if thisAddress begins with postcode then
			set postcode to ""
			set theCountry to ""
		else -- probably a valid post code
			set thisAddress to item 2 of theResult -- the string preceeding the apparent post code
			set theCountry to the last item of theResult -- the string following the apparent post code
		end if -- likely a valid post code
	end if -- post code detected
	if thisAddress is not "" then set thisAddress to removeWhiteSpaceFromEitherEndOf(thisAddress)
	-- just some logging crap
	doOBLog of OBUtility for "The string preceeding the post code is " & thisAddress given logType:"debug"
	doOBLog of OBUtility for "The post code is " & postcode given logType:"debug"
	doOBLog of OBUtility for "The string following the post code (possibly the country) is " & theCountry given logType:"debug"
	return {thisAddress, postcode, theCountry}
end extractPostCodeFrom

on extractState from thisAddress given listOfValidStates:theStates as list
	(*
this function presumes that trailing white space has been stripped from the address string before passing it to this function
if that's not a safe assumption then trailing white space should first be stripped from the address string before processing
this function now uses a constant list of known Australian states to test against
a similar but more flexible result could be achieved by using regex to search for a string of 2 or 3 characters, probably capitalised, surrounded by non-word characters, at the end of the string
it could possibly even be limited to only certain letters
such a result could detect states from other countries e.g. the US, but not all countries
such an approach would not detect states that are spelled in full, though that is relatively unlikely
*)
	doOBLog of OBUtility for "Extracting state from " & thisAddress given logType:"debug"
	set theState to "" -- so we can test to see if the following code is successful in assigning a state or not
	repeat with aState in theStates
		-- add leading space so that it matches whole words only
		if thisAddress ends with (space & aState) then
			set theState to aState
			-- #todo: it could still be part of a compound e.g. "North Queensland" in which case the following code to strip aState from the end of the address should not be executed, but how could we test for that programatically
			set theResult to regex search thisAddress search pattern "(^.*)" & (escape for regex theState) & "$" capture groups {1} with dot matches all without anchors match lines
			set thisAddress to the last item of theResult
			(* alternatively
			set x to count of characters in theState			set x to x + 1			set x to x * -1			set thisAddress to (characters 1 through x of thisAddress) as text
*)
			set thisAddress to removeWhiteSpaceFromEitherEndOf(thisAddress)
			exit repeat -- no need to continue looping as state detected
		end if
	end repeat
	doOBLog of OBUtility for "The state is " & theState & " the address is " & thisAddress given logType:"debug"
	return {thisAddress, theState}
end extractState

on extractCityFrom(thisAddress)
	doOBLog of OBUtility for "Extracting city from " & thisAddress given logType:"debug"
	-- this regex will check to see if the line ends with a comma followed by a space followed by a string of letters with optional spaces and, if so, extract that as the city with the preceeding string to be the address
	-- the key is that if there are numbers after the final comma then it's possibly still a street address and not the city
	set thisAddress to thisAddress as text -- following line errors without this coercion, for reasons unknown
	-- #todo: currently only matches one or two word strings, so doesn't match e.g. North Curl Curl. Perhaps the last grouping should be [,\\n\\r]\\s?([a-z ]+)$
	set theResult to regex search thisAddress search pattern "(^.+)[,\\n\\r]\\s?([a-z]+\\s?[a-z]*)$" capture groups {} with dot matches all without anchors match lines
	if theResult is {} then
		set theCity to ""
	else
		set theResult to the last item of theResult
		set theCity to the last item of theResult
		set thisAddress to item 2 of theResult -- the first item is the entire string
		set thisAddress to removeWhiteSpaceFromEitherEndOf(thisAddress)
	end if
	(*
			-- #todo: should probably do this with regex as per above			set theResult to split string thisAddress using delimiters {","}			if (count of items of theResult) is 1 then				set theAddress of functionResult to the first item of theResult			else				set city of functionResult to the last item of theResult				set theAddress of functionResult to join strings (items 1 through -2 of theResult) using delimiter ","			end if -- commas detected
*)
	doOBLog of OBUtility for "The city is " & theCity & " the address is " & thisAddress given logType:"debug"
	return {thisAddress, theCity}
end extractCityFrom

on removeWhiteSpaceFromEitherEndOf(thisString)
	doOBLog of OBUtility for "Removing white space from either end of: " & thisString given logType:"debug"
	set thisString to regex change thisString search pattern "^\\s+" replace template "$1"
	set thisString to regex change thisString search pattern "\\s+$" replace template "$1"
	set thisString to removeDoubleSpacesFrom(thisString)
	doOBLog of OBUtility for "The string is now: " & thisString given logType:"debug"
	return thisString
end removeWhiteSpaceFromEitherEndOf

on removeSpacesFromEitherEndOf(thisString)
	doOBLog of OBUtility for "Removing spaces from either end of: " & thisString given logType:"debug"
	set thisString to regex change thisString search pattern "^ +" replace template "$1"
	set thisString to regex change thisString search pattern " +$" replace template "$1"
	set thisString to removeDoubleSpacesFrom(thisString)
	doOBLog of OBUtility for "The string is now: " & thisString given logType:"debug"
	return thisString
end removeSpacesFromEitherEndOf

on removeDoubleSpacesFrom(thisString)
	doOBLog of OBUtility for "Removing multiple spaces from " & thisString given logType:"debug"
	return regex change thisString search pattern "  +" replace template " "
end removeDoubleSpacesFrom

