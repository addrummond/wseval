use warnings;
use strict;

use CGI;
use Template;
use JSON::XS;
use YAML::XS;

my $page = <<'END';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
[% USE Filter.Minify.CSS %]
[% USE Filter.Minify.JavaScript %]
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Winter Storm 2010 Survery</title>
<style type="text/css">
/* <![CDATA[ */
[% ROUNDING = '8px' %]
[% BODY_BACKGROUND = '#CEDFEF' %]
[% OUTER_BACKGROUND = '#FFFFFF' %]
[% HEADING = '#C65421' %]
[% VLARGE = '18pt' %]
[% LARGE = '16pt' %]
[% STDSIZE = '14pt' %]
[% SMALL = '10pt' %]
[% TEXT_COLOR = '#202020' %]
[% WEAK_COLOR = 'grey' %]
[% Q_COLOR = '#E7DBDD' %]

[% FILTER minify_css %]
body {
    font-size: 12pt;
    font-family: "Verdana", "Helvetica", "Arial", "sans-serif", "sans serif", "sansserif";
    background-color: [% BODY_BACKGROUND %];
    padding-bottom: 50px;
    color: [% TEXT_COLOR %];
}
#outer {
    width: 35em;
    margin-left: auto;
    margin-right: auto;
    padding-top: 1em;
    padding-bottom: 1em;
    padding-left: 2em;
    padding-right: 2em;
    position: relative;
    top: 25px;
    background-color: [% OUTER_BACKGROUND %];
    -moz-border-radius: [% ROUNDING %];
    -webkit-border-radius: [% ROUNDING %];
}
#outer2 { }
#contents {
    padding-bottom: 2em;
}

.qbox {
    /*padding-left: 1em;
    padding-right: 1em;
    padding-top: 0.5em;
    padding-bottom: 0.5em;*/
    padding: 1em;
    margin-bottom: 1em;
    background-color: [% Q_COLOR %];
    -moz-border-radius: [% ROUNDING %];
    -webkit-border-radius: [% ROUNDING %];
}

h1, h2, h3, h4, h5, h6 {
    color: [% HEADING %];
    text-align: center;
    position: relative;
    left: -0.5em;
}

h2 {
    font-size: [% VLARGE %];
    font-weight: bold;
}

h3 {
    font-size: [% LARGE %];
    font-weight: normal; 
}

th {
    font-weight: normal;
    text-decoration: none;
    text-align: left;
}

p.question {
    margin-top: 0;
    padding-top: 0;
    font-weight: bold;
}

input.chk {
    margin-right: 1em;
    margin-left: 0;
    padding-left: 0;
}

td input.chk {
    margin-right: 0;
}

.q-agreement table {
    margin-bottom: 1em;
    width: 30em;
}

textarea {
    margin-top: 1em;
    margin-bottom: 1em;
}

td.q-agreement-comment {
    color: [% TEXT_COLOR %];
    font-size: [% SMALL %];
    font-style: italic;
    font-weight: bold;
    margin-left: 0;
    padding-left: 0;
    margin-right: 0;
    padding-right: 0;
}

.q-agreement td {
    padding-right: 1em;
}

.nextprev {
    color: [% WEAK_COLOR %];
    font-size: [% SMALL %];
/*    font-weight: bold;*/
    font-style: italic;
    padding-top: 2em;
}

.next, .prev {
    cursor: pointer;
    font-size: [% LARGE %];
    color: [% TEXT_COLOR %];
    font-style: normal;
}
.next:hover {
    text-decoration: underline;
}
.next {
    float: right;
}
.prev {
    float: left;
}
.prev:hover {
    text-decoration: underline;
}
.pinfo {
    color: [% WEAK_COLOR %];
/*    font-weight: bold;*/
    font-size: small;
    text-align: center;
    font-style: italic;
}

.end-box {
    background: [% HEADING %];
    color: white;
    text-align: center;
    padding: 1em;
    font-weight: bold;
    -moz-border-radius: [% ROUNDING %];
    -webkit-border-radius: [% ROUNDING %];
}
div.submit {
    display: table;
    margin-top: 2em;
    margin-left: auto;
    margin-right: auto;
}
div.submit input {
    font-size: [% LARGE %];
}
div.spinner {
    background-image: url("ajax-loader.gif");
    width: 16px;
    height: 16px;
}
[% END %]
/* ]]> */
</style>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js"></script>
<script type="text/javascript">
/* <![CDATA[ */
[% FILTER minify_js %]
[% INSERT json2.js %]
[% END %]
/* <![CDATA[ */
</script>
<script type="text/javascript">
/* <![CDATA[ */
var QUESTIONS=[% questions %];
[% FILTER minify_js %]

var radioButtonGroupCounter = 0;

var uid = 1;
function mkcheck(group, value, checked) {
    var s = "<input type='" + (group !== false ? "radio" : "checkbox") + "' " + (group !== false ? "name='" + group + "' " : "") + (checked ? " checked='1'" : "") + ">";
    return $(s).addClass("chk").data('uid', uid++).data('value', value);
}

// Hack to enable faking inheritance (store the class name
// of a widget as one of it's 'data' attributes).
(function () {
    var oldW = $.widget;
    $.widget = function (name, opts) {
        var oldInit = opts._init;
        opts._init = function () {
            var s = name.split(".");
            this.element.data('widgetName', s[s.length-1]);
            return oldInit.call(this, name, opts);
        }

        return oldW(name, opts);
    };
})();

$.widget("ui.q_agreement", {
    _init: function () {
        this.element.data('widgetName', 'q_agreement'); 

        this.element.addClass("q-agreement");

        var os = this.options;
        this.element
          .append($("<p>")
                  .addClass("question")
                  .append(os.q));

        var degrees = os.degrees || 5;
        this.rbuts = [];
        var t = this;
        for (var i = 0; i < os.as.length; ++i) {
            var tab = $("<table>");
            tab.append($("<tr>").append($("<th colspan='" + (degrees+2) + "'>").append(os.as[i])));
            var tr = $("<tr>");
            tr.append($("<td>").addClass("q-agreement-comment")
                               .text("(strongly disagree)"));
            var bgroup = radioButtonGroupCounter++;

            (function (lrads) {

            for (var j = 1; j <= degrees; ++j) {
                (function (j) {
                var rad;
                tr.append($("<td>")
                          .append(j + "&nbsp;")
                          .css('cursor', 'default')
                          .click(function () {
//                                     if (! lrads[j-1].attr('checked')) {
                                         lrads[j-1].attr('checked', '1');
//                                     }
                                 }));
                })(j);
            }
            tr.append($("<td>").addClass("q-agreement-comment")
                      .text("(strongly agree)"));
            tab.append(tr);

            tr = $("<tr>");
            tr.append($("<td>"));
            for (var j = 1; j <= degrees; ++j) {
                var rad = mkcheck(bgroup, j);
                tr.append($("<td>").append(rad));
                lrads.push(rad);
                t.rbuts.push(rad);
            }
            tr.append($("<td>"));
            tab.append(tr);

            t.element.append(tab);

            })([]);
        }
    },

    getQuestion: function () { return this.options.q; },

    getAnswer: function () {
        for (var i = 0; i < this.rbuts.length; ++i) {
            if ($(this.rbuts[i]).attr('checked'))
                return this.rbuts[i].data('value');
        }
    }
});
$.ui.q_agreement.getter = 'getQuestion getAnswer';

$.widget("ui.q_comment", {
    _init : function () {
        this.element.addClass("q-comment");

        var os = this.options;
        this.element
            .append($("<p>")
                    .addClass("question")
                    .append(os.q))
            .append(this.textarea = $("<textarea rows='10' cols='50' value=''>")
                    .attr('value', '') // Needed for IE, which otherwise puts "</div>" in there (not sure why, maybe subtle bug in this code?)
                    .addClass("comment"));
    },

    getQuestion : function () { return this.options.q; },

    getAnswer : function () {
        return this.textarea.attr('value');
    }
});
$.ui.q_comment.getter = 'getQuestion getAnswer';

$.widget("ui.q_selection", {
    _init : function () {
        this.element.addClass("q-selection");

        var os = this.options;
        this.element
            .append($("<p>")
                    .addClass("question")
                    .append(os.q));
        var rbuts = $("<div>").addClass(os.mselection ? "checkbox-group" : "radio-group");
        this.rbuts = [];
        var t = this;
        var bgroup = radioButtonGroupCounter++;
        for (var i = 0; i < os.as.length; ++i) {
            (function (txt, rbut, txtspan) { // txtpsan and rbut set later (fake locals)
            rbuts.append($("<div>")
                         .addClass("radio-pair")
                         .append(rbut = mkcheck(os.mselection ? false : bgroup, txt))
                         .append(txtspan = $("<span>").append(txt).css('cursor', 'default')));
            rbut.click(function () {
                if (os.answerWatcher)
                    os.answerWatcher(txt);
            });
            t.rbuts.push(rbut);
            txtspan.click(function () {
                rbut.attr('checked', rbut.attr('checked') && os.mselection ? '' : '1');
                if (os.answerWatcher) {
                    os.answerWatcher(txt);
                }
            });
            })(os.as[i]);
        }

        this.element.append(rbuts);
    },

    setAnswerWatcher : function (v) { this.options.answerWatcher = v; },

    getQuestion : function () { return this.options.q; },

    getAnswer : function () {
        var astring = ""
        if (this.mselection) {
            for (var i = 0; i < this.rbuts.length; ++i) {
                if (this.rbuts[i].attr('checked'))
                    astring += this.rbuts[i].data('value') + ',';
            }
            return astring.replace(/,$/, '');
        }
        else {
            for (var i = 0; i < this.rbuts.length; ++i) { 
                if (this.rbuts[i].attr('checked'))
                    return this.rbuts[i].data('value');
            }
        }
    }
});
$.ui.q_selection.getter = 'getQuestion getAnswer';

$.widget("ui.paginated", {
    _init: function () {
        this.element.addClass("paginated");

        /*@cc_on
        this.checkStore = { };
        this.cboxes = [];
        @*/

        var t = this;
        function ptext() {
            return $("<div>").addClass("pinfo").text("Page " + (t.currentPageNumber+1) + " of " + t.options.pages.length);
        }

        this.currentPageNumber = 0;
        this.ptexts = [];
        if (this.options.pages.length > 1)
            this.element.append(ptext());
        this.element.append(this.pageContainer = $("<div>").addClass("page-container").append(this.options.pages[0]));
        if (this.options.pages.length > 1) {
            this.element
                .append(this.nextprev = $("<div>")
                        .addClass("nextprev")
                        .append(this.options.pages.length <= 1 ? null : ptext())
                        .append($("<div>").addClass("next").append("next &raquo;")
                                .click(function () { update(true); })));

            // :hover not working in IE (only works on <a> I think).
            var t = this;
            function dohover() {
                /*@cc_on
                function over() { $(this).css('text-decoration', 'underline'); }
                function out() { $(this).css('text-decoration', 'none'); }
                $(t.nextprev).find("*.next").hover(over, out);
                $(t.nextprev).find("*.prev").hover(over, out);
                @*/
            }
            dohover();

            function update (isNext) {
                if (isNext && t.currentPageNumber + 1 == t.options.pages.length)
                    return;
                if (! isNext && t.currentPageNumber == 0)
                    return;

                var oldp = t.currentPageNumber;
                t.currentPageNumber += isNext ? 1 : -1;

                $(t.element).find("> .pinfo").replaceWith(ptext());

                t.nextprev.empty();

                t.nextprev.append(ptext());

                if (t.currentPageNumber > 0)
                    t.nextprev.append($("<div>").addClass("prev").append("&laquo; previous")
                                      .click(function () { update(false); }));
                if (t.currentPageNumber + 1 < t.options.pages.length)
                    t.nextprev.append($("<div>").addClass("next").append("next &raquo;")
                                      .click(function () { update(true); }));

                dohover();

                /*@cc_on
                var checks1 = t.pageContainer.find("input[type='radio']");
                var checks2 = t.pageContainer.find("input[type='checkbox']");
                for (var i = 0; i < checks1.length; ++i) {
                    t.cboxes.push(checks1[i]);
                    t.checkStore[$(checks1[i]).data('uid')] = $(checks1[i]).attr('checked');
                }
                for (var i = 0; i < checks2.length; ++i) {
                    t.cboxes.push(checks2[i]);
                    t.checkStore[$(checks2[i]).data('uid')] = $(checks2[i]).attr('checked');
                }
                @*/

                // Using DOM method becuase it doesn't delete events.
                t.options.pages[oldp].parent()[0].removeChild(t.options.pages[oldp][0]);
                t.pageContainer[0].appendChild(t.options.pages[t.currentPageNumber][0]);

                /*@cc_on
                var newchecks1 = t.pageContainer.find("input[type='radio']")
                var newchecks2 = t.pageContainer.find("input[type='checkbox']");
                for (var j = 0; j < newchecks1.length; ++j) {
                    if (t.checkStore[$(newchecks1[j]).data('uid')])
                        $(newchecks1[j]).attr('checked', 1);
                }
                for (var j = 0; j < newchecks2.length; ++j) {
                    if (t.checkStore[$(newchecks2[j]).data('uid')])
                        $(newchecks2[j]).attr('checked', 1);
                }
                @*/

                document.location = "#top";
            }
        }
    },

    // Make sure that no checkboxes/radio buttons have reverted to default values.
    // (Only needed for IE 6, surprise surprise, but I'm not 100% sure that later
    // IEs don't need it also, so doing this for all IE versions).
    updateAllCheckboxes: function () {
        /*@cc_on
        for (var i = 0; i < this.cboxes.length; ++i) {
            if (this.checkStore[$(this.cboxes[i]).data('uid')])
                $(this.cboxes[i]).attr('checked', 1);
        }
        @*/
    }
});

function isQType(x) { return x == "selection" || x == "mselection" || x == "agreement" ||  x == "comment"; }

function addWatchOn(sectionDiv, triggerQ, triggerDiv) {
    triggerDiv[triggerDiv.data('widgetName')]("setAnswerWatcher", function (ans) {
        if (triggerQ.hide_remainder_if_answer_is == ans) {
            var cs = sectionDiv.children();
            for (var i = 0; i < cs.length; ++i) {
                if (cs[i] != triggerDiv[0] && ! cs[i].tagName.match(/H\d+/i))
                    $(cs[i]).hide("normal").data('exclude', true);
            }
        }
        else {
            sectionDiv.children().show("normal").data('exclude', false);
        }
    });
}

// This is a list whose members are of the following format.
//     [[section, subsection, subsubsection], questionDiv]
var g_questions = [];

function buildQ(pageDiv, q, level) {
    var qdiv;
    if (q.type == "selection")
        qdiv = $("<div>").q_selection({ q: q.q, as: q.as });
    else if (q.type == "mselection")
        qdiv = $("<div>").q_selection({ mselection: true, q: q.q, as: q.as });
    else if (q.type == "agreement")
        qdiv = $("<div>").q_agreement({ q: q.q, as: q.as });
    else if (q.type == "comment")
        qdiv = $("<div>").q_comment({ q: q.q });
    else {
        alert("ERROR: Should not get here.");
    }

    qdiv.addClass("qbox");

    if (q.hide_remainder_if_answer_is)
        addWatchOn(pageDiv, q, qdiv);

    g_questions.push([level, qdiv]);

    pageDiv.append(qdiv);
}

function buildPage (elems, pageDiv, level) {
    for (var i = 0; i < elems.length; ++i) {
        if (isQType(elems[i].type)) {
            buildQ(pageDiv, elems[i], level);
        }
        else if (elems[i].type == "section") {
            var eDiv;
            pageDiv.append(eDiv = $("<div>").append($("<h" + (level.length+2) + ">").append(elems[i].name)));
            var newlevel = [];
            for (var j = 0; j < level.length; ++j) newlevel.push(level[j]);
            newlevel.push(elems[i].name);
            buildPage(elems[i].contents, eDiv, newlevel);
        }
        else {
            alert("ERROR: Should not get here (" + elems[i].type + ")");
        }
    }
}

function makePages_ () {
    var pages = [];
    for (var i = 0; i < QUESTIONS.questions.length; ++i) {
        var page = QUESTIONS.questions[i];
        if (page.type != "section") {
            alert("ERROR: Can't handle top-level questions.");
            break;
        }

        var pageDiv = $("<div>")
                      .addClass("qpage")
                      .append($("<h2>").append(page.name));

        buildPage(page.contents, pageDiv, [page.name]);

        pages.push(pageDiv);
    }

    return pages;
}

// Adds submit button on the end of the last page.
function makePages() {
    var pages = makePages_();
    var last = pages[pages.length-1];

    var onClickFunc;
    last.append(
        $("<div>")
        .addClass("end-box")
        .append("You have completed this survey.")
        .append(
            $("<div>")
            .addClass("submit")
            .append(
                    $("<input type='submit' value='Submit responses'>")
                    .click(onClickFunc = function () {
                               var responses = getResults();

                               function onerror(e) {
                                    alert(e);
                                    $(".end-box .spinner").remove();
                                    $(".end-box")
                                    .empty()
                                    .append("There was an error submitting your results.")
                                    .append($("<div>")
                                            .addClass("submit")
                                            .append($("<input type='submit' value='Retry'>")
                                                    .click(onClickFunc)));
                               }

//                             alert(JSON.stringify(responses));

                               $(".end-box").append($("<div>").addClass("spinner"));
                               
                               var xmlhttp = $.post("survey_submit.pl", { responses: JSON.stringify(responses) }, function (response) {
                                    if (response && response.error) {
                                        onerror(response.error);
                                    }
                                    else { // Success.
                                        $(".end-box")
                                        .empty()
                                        .append("Your responses have been collected. Thanks!");
                                    }
                               }, "json");
                               xmlhttp.onreadystatechange = function () {
                                   if (xmlhttp.readyState == 4) {
                                       $(".end-box .spinner").remove();

                                       if (xmlhttp.status != 200) {
                                           onerror(xmlhttp.responseBody);
                                       }
                                   }
                               }
                           }))
         )
    );

    return pages;
}

function getResults () {
    $("#contents .paginated").paginated("updateAllCheckboxes");

    var lst = []; // Each element is of the format [[section,subsection,subsubsection,...], question, answer_data]
    for (var i = 0; i < g_questions.length; ++i) {
        var sects = g_questions[i][0];
        var div = g_questions[i][1];
        var wname = div.data('widgetName');
        lst.push([sects,
                  div[wname]("getQuestion"),
                  g_questions[i][1].data('exclude') ? null : div[wname]("getAnswer")]);
    }
    return lst;
}

$(document).ready(function () {
    window.history.forward(1);
    var pages = makePages();
    $("#contents").append($("<div>").paginated({ pages: pages }));
});

[% END %]
/* ]]> */
</script>
</head>

<body id="body">
<div id="outer">
<div id="contents">
<span id="top"></span>
</div>
</div>
</body>
</html>
END

my $questions = YAML::XS::LoadFile("questions.yml") or die "Unable to load questions.yml: $!";

my $q = CGI->new;

print $q->header(
    -type    => 'text/html', # Anything else might confuse poor old IE 6.
    -status  => '200 OK',
    -charset => 'UTF-8'
);

my $tt = Template->new();
$tt->process(\$page, { questions => JSON::XS::encode_json($questions) });
