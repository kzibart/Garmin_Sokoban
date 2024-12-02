import Toybox.Lang;
import Toybox.WatchUi;

class SokobanDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        return false;
    }

    function onBack() {
        loadgame();
        if (state == 1 and !undo) {
            if (doright()) {
                savegame();
                WatchUi.requestUpdate();
            }
            return true;
        }
        return false;
    }

    function onSwipe(swipeEvent) {
        var dir = swipeEvent.getDirection();
        loadgame();
        var test = false;
        if (state == 1 and !undo) {
            if (dir == WatchUi.SWIPE_UP) {
                test = doup();
            } else if (dir == WatchUi.SWIPE_DOWN) {
                test = dodown();
            } else if (dir == WatchUi.SWIPE_LEFT) {
                test = doleft();
            } else if (dir == WatchUi.SWIPE_RIGHT) {
                test = doright();
            }
        }
        if (test) {
            savegame();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onTap(clickEvent) {
        var pressxy = clickEvent.getCoordinates();
        loadgame();
        var test = false;
        if (circContains(pressxy, [sW/2, sH/2], sW/4)) {
            if (state == 0 and diff == 3) {
                fetchpuzzles(null);
                test = true;
            } else if (state == 1) {
                undo = !undo;
                test = true;
            }
        } else if (circContains(pressxy, [sW/2, sH/6], sW/4)) {
            test = doup();
        } else if (circContains(pressxy, [sW/2, sH*5/6], sW/4)) {
            test = dodown();
        } else if (circContains(pressxy, [sW/6, sH/2], sW/4)) {
            test = doleft();
        } else if (circContains(pressxy, [sW*5/6, sH/2], sW/4)) {
            test = doright();
        }
        if (test) {
            WatchUi.requestUpdate();
            savegame();
            return true;
        }
        return false;
    }

    function doup() {
        if (state == 0) {
            diff = (diff + 1) % allpuzzles.size();
            thispuzz = 0;
            newgame();
            return true;
        } else if (state == 1) {
            if (!undo) {
                return moveit([-1,0]);
            }
        }
        return false;
    }
    function dodown() {
        if (state == 0) {
            state = 1;
            return true;
        } else if (state == 1) {
            if (undo) {
                state = 0;
                newgame();
                return true;
            } else {
                return moveit([1,0]);
            }
        }
        return false;
    }
    function doleft() {
        if (state == 0) {
            return prevpuzz();
        } else if (state == 1) {
            if (undo) {
                return undoit();
            } else {
                return moveit([0,-1]);
            }
        } else if (state == 2) {
            state = 0;
            newgame();
            return true;
        }
        return false;
    }
    function doright() {
        if (state == 0) {
            return nextpuzz();
        } else if (state == 1) {
            if (undo) {
                return redoit();
            } else {
                return moveit([0,1]);
            }
        } else if (state == 2) {
            state = 1;
            return nextpuzz();
        }
        return false;
    }

    // See if a point is within a circle
    public function circContains(point, circle, rad) {
        var x = point[0];
        var y = point[1];
        var cx = circle[0];
        var cy = circle[1];
        return ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= rad * rad);
    }

}