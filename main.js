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
        this.degrees = degrees;
        this.rbuts = [];
        var t = this;
        for (var i = 0; i < os.as.length; ++i) {
            var tab = $("<table>");
 //           tab.append($("<tr>").append($("<th colspan='" + (degrees+2) + "'>").append(os.as[i])));
            var tr = $("<tr>");
            tr.append($("<td>").addClass("q-agreement-comment")
                               .addClass("q-agreement-comment-left")
                               .text("(strongly disagree)"));
            var bgroup = radioButtonGroupCounter++;

            (function (lrads) {

            for (var j = 1; j <= degrees; ++j) {
                (function (j) {
                var rad;
                tr.append($("<td>")
                          .addClass("q-agreement-number")
                          .append(j + "&nbsp;")
                          .css('cursor', 'default')
                          .click(function () {
//                                     if (! lrads[j-1].attr('checked')) {
                                         lrads[j-1].attr('checked', '1');
//                                     }
                                 }));
                })(j);
            }
            tr.append($("<td>")
                      .addClass("q-agreement-comment")
                      .addClass("q-agreement-comment-right")
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

            t.element.append($("<p>").addClass("q-agreement-question").append(os.as[i]));
            t.element.append(tab);

            })([]);
        }
    },

    getAnswer: function () {
        var ans = [];
        for (var i = 0; i < this.options.as.length; ++i) {
            var resLine = [this.options.q + '/' + this.options.as[i], null];
            for (var j = 0; j < this.degrees; ++j) {
                if ($(this.rbuts[(i*this.degrees)+j]).attr('checked')) {
                    oneWasSelected = true;
                    resLine[1] = this.rbuts[(i*this.degrees)+j].data('value');
                }
            }
            ans.push(resLine);
        }
        return ans;
    }
});
$.ui.q_agreement.getter = 'getAnswer';

$.widget("ui.q_comment", {
    _init : function () {
        this.element.addClass("q-comment");

        var os = this.options;
        this.element
            .append($("<p>")
                    .addClass("question")
                    .append(os.q))
            .append(this.textarea = $("<textarea rows='10' cols='75' value=''>")
                    .attr('value', '') // Needed for IE, which otherwise puts "</div>" in there (not sure why, maybe subtle bug in this code?)
                    .addClass("comment"));
    },

    getAnswer : function () {
        return [ [this.options.q, this.textarea.attr('value') ] ];
    }
});
$.ui.q_comment.getter = 'getAnswer';

$.widget("ui.q_selection", {
    _init : function () {
        this.element.addClass("q-selection");

        if (this.options.has_other && this.options.mselection) {
            alert("ERROR: Impossible combination of options for 'q_selection' widget.");
            return;
        }

        var os = this.options;
        this.element
            .append($("<p>")
                    .addClass("question")
                    .append(os.q));
        var rbuts = $("<table>");
        this.rbuts = [];
        var t = this;
        var bgroup = radioButtonGroupCounter++;
        for (var i = 0; i < (this.options.has_other ? os.as.length + 1 : os.as.length); ++i) {
            (function (i, txt, rbut, txtspan, othertxt) { // txtpsan and rbut and othertxt set later (fake locals)
            var tr;
            rbuts.append(tr = $("<tr>")
                         .append($("<td>").append(rbut = mkcheck(os.mselection ? false : bgroup, txt))));
            if (i < os.as.length)
                tr.append($("<td>").addClass("ans").append(txtspan = $("<span>").append(txt).css('cursor', 'default')));
            else {
                tr.append($("<td>").addClass("ans").append(othertxt = $("<span>").css('cursor', 'default').html("Other:&nbsp;")).append(txtspan = $("<input type='text' size='20' value=''>")));
                rbut.data('istext', txtspan);
            }
            rbut.click(function () {
                if (i == os.as.length)
                    txtspan.get(0).focus();
                if (os.answerWatcher)
                    os.answerWatcher(txt);
            });
            t.rbuts.push(rbut);
            txtspan.click(function () {
                if (i == os.as.length)
                    txtspan.get(0).focus();
                rbut.attr('checked', rbut.attr('checked') && os.mselection ? '' : '1');
                if (os.answerWatcher) {
                    os.answerWatcher(txt);
                }
            });
            if (othertxt)
                othertxt.click(function () {
                    txtspan.get(0).focus();
                    rbut.attr('checked', '1'); // Note that it cannot be an mselection.
                });
            })(i, i < os.as.length ? os.as[i] : null);
        }

        this.element.append(rbuts);
    },

    setAnswerWatcher : function (v) { this.options.answerWatcher = v; },

    ishiding : function () {
        if (this.options.mselection || ! this.element.data('hide_remainder_if_answer_is'))
            return false;
        var oneIsChecked = false;
        for (var i = 0; i < this.rbuts.length; ++i) {
            if (this.rbuts[i].attr('checked')) {
                oneIsChecked = true;
                if (this.rbuts[i].data('value') == this.element.data('hide_remainder_if_answer_is'))
                    return true;
            }
        }
        return ! oneIsChecked;
    },

    getAnswer : function () {
        var astring = ""
        if (this.options.mselection) {
            for (var i = 0; i < this.rbuts.length; ++i) {
                if (this.rbuts[i].attr('checked'))
                    astring += this.rbuts[i].data('value') + ',';
            }
            return [ [ this.options.q, astring.replace(/,$/, '') ] ];
        }
        else {
            for (var i = 0; i < this.rbuts.length; ++i) { 
                if (this.rbuts[i].attr('checked'))
                    return [ [ this.options.q,
                               this.rbuts[i].data('istext') ? this.rbuts[i].data('istext').attr('value') : this.rbuts[i].data('value') ] ];
            }
            return [ [ this.options.q, null ] ];
        }
    }
});
$.ui.q_selection.getter = 'getAnswer ishiding';

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

                if (window.scrollTo)
                    window.scrollTo(0, 0);
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

function recShow(div) {
    var cs = div.children();
    var inHiding = false;
    for (var i = 0; i < cs.length && ! inHiding; ++i) {
        if ($(cs[i]).data('isSection')) {
            recShow($(cs[i]));
        }
        else if ($(cs[i]).data('widgetName') || cs[i].tagName.match(/H\d+/)) {
            $(cs[i]).show("normal").data('exclude', false);
            if (! inHiding && $(cs[i]).data('widgetName') == "q_selection") inHiding = $(cs[i]).q_selection("ishiding");
        }
    }
}
function recHide(div, triggerDiv) {
    var cs = div.children();
    var afterTrigger = ! triggerDiv;
    for (var i = 0; i < cs.length; ++i) {
        if (triggerDiv && cs[i] == triggerDiv[0]) afterTrigger = true;
        else if (afterTrigger) {
            if ($(cs[i]).data('isSection')) {
                recHide($(cs[i]));
            }
            else if ($(cs[i]).data('widgetName') || cs[i].tagName.match(/H\d+/)) {
                $(cs[i]).hide("normal").data('exclude', true);
                //alert("EXCLUDE: " + cs[i].innerHTML);
            }
        }
    }
}

function addWatchOn(sectionDiv, triggerQ, triggerDiv) {
    triggerDiv[triggerDiv.data('widgetName')]("setAnswerWatcher", function (ans) {
        if (triggerQ.hide_remainder_if_answer_is == ans) {
            recHide(sectionDiv, triggerDiv);
        }
        else {
            recShow(sectionDiv);
        }
    });
    triggerDiv.data('hide_remainder_if_answer_is', triggerQ.hide_remainder_if_answer_is);
}

// This is a list whose members are of the following format.
//     [[section, subsection, subsubsection], questionDiv]
var g_questions = [];

function buildQ(pageDiv, q, level) {
    var qdiv;
    if (q.type == "selection")
        qdiv = $("<div>").q_selection({ q: q.q, as: q.as, has_other: q.has_other });
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
    return qdiv;
}

function buildPage (elems, pageDiv, level, hiding) {
    for (var i = 0; i < elems.length; ++i) {
        if (isQType(elems[i].type)) {
            var qdiv = buildQ(pageDiv, elems[i], level);
            if (hiding)
                qdiv.hide().data('exclude', true);
            if (elems[i].hide_remainder_if_answer_is)
                hiding = true;
        }
        else if (elems[i].type == "section") {
            var eDiv;
            var h;
            pageDiv.append(eDiv = $("<div>").append(h = $("<h" + (level.length+2) + ">").append(elems[i].name)));
            if (hiding) { h.hide(); }
            var newlevel = [];
            for (var j = 0; j < level.length; ++j) newlevel.push(level[j]);
            newlevel.push(elems[i].name);
            eDiv.data('isSection', true);
            buildPage(elems[i].contents, eDiv, newlevel, hiding);
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
                               
                               $.ajax({
                                   url: "survey_submit.pl",
                                   type: "POST",
                                   data: { responses: JSON.stringify(responses) },
                                   dataType: "json",
                                   global: false,
                                   success: function (response) {
                                       $(".end-box .spinner").remove();

                                       if (response && response.error) {
                                           onerror(response.error);
                                       }
                                       else { // Success.
                                           $(".end-box")
                                           .empty()
                                           .append("Your responses have been collected. Thanks!");
                                       }
                                   },
                                   error: function (xmlhttp, textStatus) {
                                       $(".end-box .spinner").remove();
                                       onerror(xmlhttp.responseBody || textStatus);
                                   }
                               });
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
        var ans = div[wname]("getAnswer");
        for (var j = 0; j < ans.length; ++j) {
            lst.push([sects,
                      ans[j][0],
                      g_questions[i][1].data('exclude') ? null : ans[j][1]]);
        }
    }
    return lst;
}

$(document).ready(function () {
    window.history.forward(1);
    var pages = makePages();
    $("#contents").append($("<div>").paginated({ pages: pages }));
});

