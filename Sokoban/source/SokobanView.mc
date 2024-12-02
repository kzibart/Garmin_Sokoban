import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Math;
import Toybox.Lang;
import Toybox.Communications;

var dS = System.getDeviceSettings();
var sW = dS.screenWidth;
var sH = dS.screenHeight;

var game,state,solved,gamehist,lasthist,diff,thispuzz,undo,rows,cols,online;
var puzzle,maxdiff,maxpuzz;

var gridXY,gridWH,cell,loc;

var center = Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER;

class SokobanView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        gridXY = [sW*15/100,sH*15/100];
        gridWH = [sW*70/100,sH*70/100];
        maxdiff = allpuzzles.size()-1;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        loadgame();
        if (state == 0) {
            dc.setColor(0,0x000044);
        } else if (state == 1) {
            if (undo) {
                dc.setColor(0,0x440000);
            } else {
                dc.setColor(0,0);
            }
        } else {
            dc.setColor(0,0x004400);
        }
        dc.clear();

        cell = gridWH[0]/cols;
        if (cell > gridWH[1]/rows) {
            cell = gridWH[1]/rows;
        }
        gridXY[0] = (sW-(cell*cols))/2;
        gridXY[1] = (sH-(cell*rows))/2;

        if (puzzle.length() == 0) {
            dc.setColor(Graphics.COLOR_WHITE,-1);
            dc.drawText(sW/2, sH/2, Graphics.FONT_SMALL, "TAP HERE\nTO LOAD\nPUZZLES", center);
        } else {
            for (var r=0;r<rows;r++) {
                for (var c=0;c<cols;c++) {
                    var x = gridXY[0]+cell*c;
                    var y = gridXY[1]+cell*r;
                    var char = getchar(r,c);
                    drawit(dc,char,x,y,cell);
                }
            }
        }

        maxpuzz = allpuzzles[diff].size()-1;
        var d = "";
        if (diff == 0) { d = "EASY"; }
        else if (diff == 1) { d = "MEDIUM"; }
        else if (diff == 2) { d = "HARD"; }
        else { d = "ONLINE"; }
        var l = null;
        if (diff < 3) {
            if (solved[diff][thispuzz] != null) {
                l = solved[diff][thispuzz];
            }
        }
        if (state == 0) {
            // New game display
            if (l == null) {
                dc.setColor(Graphics.COLOR_WHITE,-1);
            } else {
                dc.setColor(Graphics.COLOR_GREEN,-1);
            }
            dc.drawText(sW/2, sH*10/100, Graphics.FONT_XTINY, d+" "+(thispuzz+1)+"/"+allpuzzles[diff].size(), center);
            dc.setColor(Graphics.COLOR_WHITE,-1);
            var p = "";
            if (l == null) {
                p = "PLAY";
            } else {
                p = "REPLAY ("+l+")";
            }
            dc.drawText(sW/2, sH*90/100, Graphics.FONT_XTINY, p, center);
            if (thispuzz > 0) { dc.setColor(Graphics.COLOR_WHITE,-1); }
            else { dc.setColor(Graphics.COLOR_DK_GRAY,-1); }
            dc.drawText(sW*10/100, sH/2, Graphics.FONT_XTINY, "P\nR\nE\nV", center);
            if (thispuzz < maxpuzz) { dc.setColor(Graphics.COLOR_WHITE,-1); }
            else { dc.setColor(Graphics.COLOR_DK_GRAY,-1); }
            dc.drawText(sW*90/100, sH/2, Graphics.FONT_XTINY, "N\nE\nX\nT", center);
        } else if (state == 2) {
            // End of game display
            dc.setColor(Graphics.COLOR_LT_GRAY,-1);
            dc.drawText(sW/2,sH*10/100, Graphics.FONT_XTINY, d+" "+(thispuzz+1)+"/"+allpuzzles[diff].size(), center);
            var m = lasthist+" MOVE";
            if (lasthist != 1) { m += "S"; }
            dc.setColor(Graphics.COLOR_LT_GRAY,-1);
            dc.drawText(sW/2, sH*90/100, Graphics.FONT_XTINY, m, center);
            dc.setColor(Graphics.COLOR_WHITE,-1);
            dc.drawText(sW*10/100, sH/2, Graphics.FONT_XTINY, "M\nE\nN\nU", center);
            if (diff < maxdiff or thispuzz < maxpuzz) { dc.setColor(Graphics.COLOR_WHITE,-1); }
            else { dc.setColor(Graphics.COLOR_DK_GRAY,-1); }
            dc.drawText(sW*90/100, sH/2, Graphics.FONT_XTINY, "N\nE\nX\nT", center);
        } else if (undo) {
            // Playing / undo mode
            dc.setColor(Graphics.COLOR_LT_GRAY,-1);
            dc.drawText(sW/2, sH*10/100, Graphics.FONT_XTINY, "MOVE "+lasthist+"/"+(gamehist.size()-1), center);
            dc.setColor(Graphics.COLOR_WHITE,-1);
            dc.drawText(sW/2, sH*90/100, Graphics.FONT_XTINY, "MENU", center);
            if (lasthist > 0) { dc.setColor(Graphics.COLOR_WHITE,-1); }
            else { dc.setColor(Graphics.COLOR_DK_GRAY,-1); }
            dc.drawText(sW*10/100, sH/2, Graphics.FONT_XTINY, "U\nN\nD\nO", center);
            if (lasthist < gamehist.size()-1) { dc.setColor(Graphics.COLOR_WHITE,-1); }
            else { dc.setColor(Graphics.COLOR_DK_GRAY,-1); }
            dc.drawText(sW*90/100, sH/2, Graphics.FONT_XTINY, "R\nE\nD\nO", center);
        } else {
            // Playing / normal mode
            dc.setColor(Graphics.COLOR_LT_GRAY,-1);
            dc.drawText(sW/2,sH*10/100, Graphics.FONT_XTINY, d+" "+(thispuzz+1)+"/"+allpuzzles[diff].size(), center);
            var m = lasthist+" ";
            if (l == null) {
                if (lasthist == 1) {
                    m += "MOVE";
                } else {
                    m += "MOVES";
                }
            } else {
                m += "("+l+")";
            }
            dc.setColor(Graphics.COLOR_LT_GRAY,-1);
            dc.drawText(sW/2, sH*90/100, Graphics.FONT_XTINY, m, center);
        }

    }

    // #=wall, @=player, +=player on goal, $=box, *=box on goal, .=empty goal, space=empty space
    function drawit(dc,char,x,y,c) {
        var w = c;
        var h = c;
        if (char.equals("-")) { return; }
        if (char.equals("#")) {
            // Wall
            dc.setColor(Graphics.COLOR_ORANGE,-1);
            dc.fillRectangle(x,y,w,h);
        } else {
            if (char.equals(".") or char.equals("*") or char.equals("+")) {
                // Goal
                dc.setColor(Graphics.COLOR_WHITE,-1);
                dc.setPenWidth(w*10/100);
                dc.drawRectangle(x+w*5/100,y+h*5/100,w*90/100,h*90/100);
            }
            dc.setColor(Graphics.COLOR_DK_GRAY,-1);
            dc.setPenWidth(1);
            dc.drawRectangle(x,y,w,h);
        }
        if (char.equals("$") or char.equals("*")) {
            // Box
            dc.setColor(Graphics.COLOR_DK_RED,-1);
            dc.fillRectangle(x+w*10/100,y+h*10/100,w*80/100,h*80/100);
        } else if (char.equals("@") or char.equals("+")) {
            // Player
            dc.setColor(Graphics.COLOR_DK_GREEN,-1);
            dc.fillRectangle(x+w*10/100,y+h*10/100,w*80/100,h*80/100);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}

function getpuzzle(d,n) {
    var puz;
    if (allpuzzles[d].size() == 0) {
        puzzle = "";
        return;
    }
    if (n == -1) {
        puz = allpuzzles[d][Math.rand() % allpuzzles[d].size()];
    } else {
        puz = allpuzzles[d][n];
    }
    parsepuzzle(puz);
}
function parsepuzzle(puz) {
    var p = [];
    var row = new [0];
    var chr = "";
    var max = 0;
    for (var i=0;i<puz.length();i++) {
        chr = puz.substring(i,i+1);
        if (chr.equals("|")) {
            p.add(row);
            if (row.size() > max) { max = row.size(); }
            row = new [0];
        } else {
            if ("0123456789".find(chr) != null) {
                var num = chr.toNumber();
                i++;
                if ("0123456789".find(puz.substring(i,i+1)) != null) {
                    num = puz.substring(i-1,i+1).toNumber();
                    i++;
                }
                chr = puz.substring(i,i+1);
                for (var k=0;k<num;k++) {
                    row.add(chr);
                }
            } else {
                row.add(chr);
            }
        }
    }
    p.add(row);
    rows = p.size();
    cols = max;
    for (var i=0;i<p.size();i++) {
        row = p[i];
        for (var j=row.size();j<max;j++) {
            row.add(" ");
        }
        p[i] = row;
    }

    // change edge spaces to dashes for left/right
    for (var i=0;i<rows;i++) {
        for (var j=0;j<cols;j++) {
            if (p[i][j].equals("#")) { break; }
            if (p[i][j].equals(" ")) { p[i][j] = "-"; }
        }
        for (var j=cols-1;j>=0;j--) {
            if (p[i][j].equals("#")) { break; }
            if (p[i][j].equals(" ")) { p[i][j] = "-"; }
        }
    }
    // change edge spaces to dashes for top/bottom
    for (var j=0;j<cols;j++) {
        for (var i=0;i<rows;i++) {
            if (p[i][j].equals("#")) { break; }
            if (p[i][j].equals(" ")) { p[i][j] = "-"; }
        }
        for (var i=rows-1;i>=0;i--) {
            if (p[i][j].equals("#")) { break; }
            if (p[i][j].equals(" ")) { p[i][j] = "-"; }
        }
    }

    // Change from array to string
    puzzle = "";
    for (var r=0;r<rows;r++) {
        row = p[r];
        for (var c=0;c<cols;c++) {
            puzzle += row[c];
        }
    }

    getloc();
    addhist();
}

function getloc() {
    for (var r=0;r<rows;r++) {
        for (var c=0;c<cols;c++) {
            var char = getchar(r,c);
            if (char.equals("@") or char.equals("+")) {
                loc = [r,c];
                return;
            }
        }
    }
}

function getchar(r,c) {
    var i = r*cols+c;
    return puzzle.substring(i,i+1);
}

function setchar(r,c,char) {
    var i = r*cols+c;
    var s = "";
    var e = "";
    if (i > 0) { s = puzzle.substring(0,i); }
    if (i < puzzle.length()-1) { e = puzzle.substring(i+1,puzzle.length()); }
    puzzle = s+char+e;
}

// move player by d, where d is [r,c]
// #=wall, @=player, +=player on goal, $=box, *=box on goal, .=empty goal, space=empty space
function moveit(d) {
    var r = loc[0];
    var c = loc[1];
    var r1 = r+d[0];
    var c1 = c+d[1];
    var r2 = r1+d[0];
    var c2 = c1+d[1];
    if (r1 < 0 or c1 < 0 or r1 > rows-1 or c1 > cols-1) { return false; }
    var t = getchar(r1,c1);
    if (t.equals(" ") or t.equals(".")) {
        moveplayer([r,c],[r1,c1]);
        addhist();
        return true;
    } else if (t.equals("$") or t.equals("*")) {
        if (r2 < 0 or c2 < 0 or r2 > rows-1 or c2 > cols-1) { return false; }
        var u = getchar(r2,c2);
        if (u.equals(" ") or u.equals(".")) {
            movebox([r1,c1],[r2,c2]);
            moveplayer([r,c],[r1,c1]);
            addhist();
            return true;
        }
    }
    return false;
}
function moveplayer(s,e) {
    var sc = getchar(s[0],s[1]);
    var ec = getchar(e[0],e[1]);
    if (sc.equals("+")) { sc = "."; }
    else { sc = " "; }
    if (ec.equals(".")) { ec = "+"; }
    else { ec = "@"; }
    setchar(s[0],s[1],sc);
    setchar(e[0],e[1],ec);
    loc = e;
}
function movebox(s,e) {
    var sc = getchar(s[0],s[1]);
    var ec = getchar(e[0],e[1]);
    if (sc.equals("*")) { sc = "."; }
    else { sc = " "; }
    if (ec.equals(".")) { ec = "*"; }
    else { ec = "$"; }
    setchar(s[0],s[1],sc);
    setchar(e[0],e[1],ec);
}

function nextpuzz() {
    if (thispuzz == allpuzzles[diff].size()-1) {
        return false;
    } else {
        thispuzz++;
    }
    newgame();
    return true;
}

function prevpuzz() {
    if (thispuzz == 0) {
        return false;
    } else {
        thispuzz--;
    }
    newgame();
    return true;
}

function addhist() {
    if (lasthist < gamehist.size()-1) {
        gamehist = gamehist.slice(0,lasthist);
    }
    gamehist.add(puzzle);
    lasthist = gamehist.size()-1;
}

function undoit() {
    if (lasthist <= 0) { return false; }
    lasthist--;
    puzzle = gamehist[lasthist];
    getloc();
    savegame();
    return true;
}

function redoit() {
    if (lasthist >= gamehist.size()-1) { return false; }
    lasthist++;
    puzzle = gamehist[lasthist];
    getloc();
    savegame();
    return true;
}

function newgame() {
    gamehist = [];
    lasthist = 0;
    getpuzzle(diff,thispuzz);
    undo = false;
    savegame();
}

function savegame() as Void {
    if (state == 1) {
        if (puzzle.find(".") == null and puzzle.find("+") == null) {
            if (diff < 3) {
                if (solved[diff][thispuzz] != null) {
                    if (solved[diff][thispuzz] > lasthist) {
                        // New best score for this puzzle!
                    }
                }
                solved[diff][thispuzz] = lasthist;
            }
            state = 2;
        }
    }

    game = {
        "ver" => 1,
        "state" => state,
        "solved" => solved,
        "undo" => undo,
        "rows" => rows,
        "cols" => cols,
        "gamehist" => gamehist,
        "lasthist" => lasthist,
        "thispuzz" => thispuzz,
        "diff" => diff
    };
    Storage.setValue("game",game);
}

function loadgame() {
    game = Storage.getValue("game");
//game = null;
    if (game == null) { 
        state = 0;
        diff = 0;
        thispuzz = 0;
        newgame();
    }
    state = game.get("state");
    solved = game.get("solved");
    if (solved == null) {
        solved = new [0];
        for (var i=0;i<allpuzzles.size();i++) {
            var x = new [0];
            for (var j=0;j<allpuzzles[i].size();j++) {
                x.add(null);
            }
            solved.add(x);
        }
    }
    undo = game.get("undo");
    rows = game.get("rows");
    cols = game.get("cols");
    gamehist = game.get("gamehist");
    lasthist = game.get("lasthist");
    diff = game.get("diff");
    thispuzz = game.get("thispuzz");
    if (gamehist.size() == 0) {
        puzzle = "";
        rows = 10;
        cols = 10;
        loc = [0,0];
    } else {
        puzzle = deepcopy(gamehist[lasthist]);
        getloc();
    }
}

function deepcopy(input)
{
    var result = null;

    if (input == null) {
        // do nothing
    }
    if (input instanceof Lang.Array) {
        if (input.size() == 0) { result = []; }
        else {
            result = new [ input.size() ];
            for (var i = 0; i < result.size(); ++i) {
                result[i] = deepcopy(input[i]);
            }
        }
    }
    else if (input instanceof Lang.Dictionary) {
        var keys = input.keys();
        var vals = input.values();

        result = {};
        for (var i = 0; i < keys.size(); ++i) {
            var key_copy = deepcopy(keys[i]);
            var val_copy = deepcopy(vals[i]);
            result.put(key_copy, val_copy);
        }
    }
    else if (input instanceof Lang.String) {
        return input.substring(0, input.length());
    }
//    else if (input instanceof Lang.ByteArray) {
//        result = input.slice(null, null);
//    }
    else if (input instanceof Lang.Long) {
        return 1 * input;
        
    }
    else if (input instanceof Lang.Double) {
        return 1.0 * input;
    }
    else {
        // primitive types (Number/Float/Boolean/Char) are always copied
        result = input;
    }

    return result;
}

function p(s) {
    System.println(s);
}

function fetchpuzzles(callBack) {
    var options = {
        :method => Communications.HTTP_REQUEST_METHOD_GET,
        :headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
    };
    Communications.makeWebRequest("https://script.google.com/macros/s/AKfycbxra-8SlQZjDNN_deGUn3oS1oNzcsWxhRSYpJTSeV8PdERbvgtMoGKMh5VuThFhhE6qSQ/exec", null, options, (callBack == null ? new Lang.Method($, :onReceivePuzzle) : callBack));
}

function onReceivePuzzle(responseCode, data) {
    allpuzzles[3] = data.get("data");
    diff = 3;
    thispuzz = 0;
    newgame();
    WatchUi.requestUpdate();
}
