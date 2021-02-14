## 0.0.1

* Initial release of location tracking, geofencing and geo APIs

## 0.0.2

* add getLocation function
* Trip tracking via SDK
* Handle android detached from engine failed method calls (move receiver to activity from manifest)
* change setMetadata function input from `<String, String>` to `<String, dynamic>`

## 0.0.3
* change positional to named arguments for search endpoints (geofences,places,points)
* allow for trip metadata and geofence metadata search
* handle null locations properly on iOS in search endpoints

## 0.0.3+1
* remove callback_dispatcher

## 0.0.3+2
* ability to start and stop a foreground location service

## 0.0.3+3
* push receiver back to manifest