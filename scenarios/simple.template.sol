// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract StoryModel {
    enum Char {
        NOBODY,
        CHAR1,
        CHAR2,
        CHAR3
    }
    uint8 numChars = 4;
    enum Place {
        BEDROOM,
        KITCHEN,
        DINING,
        BATHROOM
    }
    uint8 numPlaces = 4;

    // Clues
    event SawWhenLeaving(uint8 char0, uint8 char1, bool bool0, uint8 place, uint256 time);
    event SawWhenArriving(uint8 char0, uint8 char1, bool bool0, uint8 place, uint256 time);
    event NotSawWhenLeaving(uint8 char0, uint8 char1, uint8 place, uint256 time);
    event NotSawWhenArriving(uint8 char0, uint8 char1, uint8 place, uint256 time);
	event Stayed(uint8 char0, uint8 place, uint256 time0, uint256 time1);
	event WasMurdered(uint8 char0, uint8 place, uint256 time);
	event FinalLocation(uint8 char0, uint8 place);
	event PoliceArrived(uint256 time);

    mapping(Char => Place) private currentLocation;
    mapping(Char => uint256) private lastMovement;
    mapping(Char => Place) private finalLocation;
    mapping(Char => bool) private changedLocation;
	mapping(Place => mapping(Place => bool)) private connection;
    Place locationWeapon;
    Char victimIdentity = Char.NOBODY;
    Char killerIdentity = Char.NOBODY;

    Char weaponOwner = Char.NOBODY;
    bool victimKilled = false;
    uint256 time;
    uint256 numberOfMoves;
    uint256 minNumberOfMoves;

    constructor() {
        // Places connections
        //$connectionLocations

        // This should be randomly generated
        //$currentLocations

        //$locationWeapon
        minNumberOfMoves = 1;
        // End of generated code
    }

    function takesWeapon(uint8 char) public {
        require(char > 0);
        char = char % numChars;
        require(Char(char) != victimIdentity);
        require(currentLocation[Char(char)] == locationWeapon);

        // No one is here, except the potential killer
        for (uint8 c = 1; c < numChars; c++) {
            if (c == char) continue;

            require(currentLocation[Char(c)] != currentLocation[Char(char)]);
        }

        weaponOwner = Char(char);
    }

    function sawEvents(uint8 char, uint8 place) internal {
		bool sawSomeone;

		sawSomeone = false;
        for (uint8 c = 1; c < numChars; c++) {
            if (c == char) continue;

			bool wasAlive = Char(c) != victimIdentity;
            if (currentLocation[Char(c)] == currentLocation[Char(char)]) {
                emit SawWhenLeaving(char, c, wasAlive, uint8(currentLocation[Char(char)]), time);
                sawSomeone = true;
            }
        }
        if (!sawSomeone) // No one was there
			emit SawWhenLeaving(char, uint8(Char.NOBODY), true, uint8(currentLocation[Char(char)]), time);
		else {
			// Someone was there, so have some negatives clues
			for (uint8 c = 1; c < numChars; c++) {
				if (c == char) continue;

				if (currentLocation[Char(c)] != currentLocation[Char(char)]) {
					emit NotSawWhenLeaving(char, c, uint8(currentLocation[Char(char)]), time);
				}
			}
		}

		time = time + 15 minutes;

        sawSomeone = false;
        for (uint8 c = 1; c < numChars; c++) {
            if (c == char) continue;

            if (currentLocation[Char(c)] == Place(place)) {
				bool wasAlive = Char(c) != victimIdentity;
				emit SawWhenArriving(char, c, wasAlive, place, time);
                sawSomeone = true;
            }
        }
        if (!sawSomeone)
			emit SawWhenArriving(char, uint8(Char.NOBODY), true, place, time);
		else {
			for (uint8 c = 1; c < numChars; c++) {
				if (c == char) continue;

				if (currentLocation[Char(c)] != Place(place)) {
					emit NotSawWhenArriving(char, c, place, time);
				}
			}
		}
    }

	function checkConnection(Place p0, Place p1) view internal returns (bool) {
        return (connection[p0][p1] || connection[p1][p0]);
	}

    function stay() internal {
        time = time + 15 minutes;
        numberOfMoves++;
    }

    function move(uint8 char, uint8 place) public {
        require(char > 0);
        char = char % numChars;
        require(Char(char) != victimIdentity);

        place = place % numPlaces;
        require(checkConnection(currentLocation[Char(char)], Place(place)));

        if (lastMovement[Char(char)] == time)
            stay();

        emit Stayed(char, uint8(currentLocation[Char(char)]), lastMovement[Char(char)], time);
        sawEvents(char, place);
        currentLocation[Char(char)] = Place(place);
		changedLocation[Char(char)] = true;
        numberOfMoves++;
        lastMovement[Char(char)] = time;
    }

    function kills(uint8 char, uint8 char1) public {
        uint8 killer = char % numChars;
        uint8 victim = char1 % numChars;
        require(Char(victimIdentity) == Char.NOBODY);
        require(killer > 0); // No nobodies
        require(victim > 0); // No nobodies

        require(killer != victim); // No suicides
        require(weaponOwner == Char(killer)); // Killer has weapon
        require(currentLocation[Char(killer)] == currentLocation[Char(victim)]);
        require(currentLocation[Char(victim)] == finalLocation[Char(victim)]);

        // No one is here, except victim and killer
        for (uint8 c = 1; c < numChars; c++) {
            if (c == killer || c == victim) continue;

            require(currentLocation[Char(c)] != currentLocation[Char(killer)]);
        }

        victimKilled = true;
        victimIdentity = Char(victim);
        killerIdentity = Char(killer);
        emit WasMurdered(victim, uint8(currentLocation[Char(killer)]), time);
    }

    function mysteryNotSolved() public returns (bool) {
        if (numberOfMoves < minNumberOfMoves) return true;
        // Victim is dead
        if (!victimKilled) return true;

        // Killer leaves the crime scene
        if (
            currentLocation[Char(killerIdentity)] ==
            currentLocation[Char(victimIdentity)]
        ) return true;

        for (uint8 char = 1; char < numChars; char++) {
			if (!changedLocation[Char(char)])
				return true;
        }
        emit PoliceArrived(time + 15 minutes);
        for (uint8 char = 1; char < numChars; char++)
            emit FinalLocation(char, uint8(currentLocation[Char(char)]));

        return false;
    }
}
