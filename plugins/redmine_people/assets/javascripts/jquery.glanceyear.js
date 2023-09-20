(function ($) {
  $.fn.glanceyear = function (massive, options) {

    var $_this = $(this);

    var settings = $.extend({
      eventClick: function (e) { },
      months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      weeks: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
      tagId: 'glanceyear-svgTag',
      dateFrom: new Date(new Date().getFullYear(), 0, 1),
      dateTo: new Date(new Date().getFullYear(), 11, 31)
    }, options);

    var svgElement = createElementSvg('svg', {'width': 54 * 17 + 15, 'height': 7 * 17 + 15});

    var gElementContainer = createElementSvg('g', {'transform': 'translate(25, 15)'});

    var $_tag = $('<div>')
      .addClass('svg-tag')
      .attr('id', settings.tagId)
      .appendTo($('body'))
      .hide();

    var dayCount = diffDays(settings.dateFrom, settings.dateTo);
    var monthCount;

    // Weeks
    for (var i = 0; i < 54; i++) {
      var gElement = createElementSvg('g', {'transform': 'translate(' + (17 * i) + ',0)'});
      var firstDate = new Date();
      firstDate.setMonth(settings.dateTo.getMonth());
      firstDate.setFullYear(settings.dateTo.getFullYear());
      firstDate.setDate(settings.dateTo.getDate() - dayCount - 1);

      var daysLeft = daysInMonth(firstDate) - firstDate.getDate();

      // Days in week
      for (var j = firstDate.getDay(); j < 7; j++) {

        var rectDate = new Date();
        rectDate.setMonth(settings.dateTo.getMonth());
        rectDate.setFullYear(settings.dateTo.getFullYear());
        rectDate.setDate(settings.dateTo.getDate() - dayCount);

        if (rectDate.getMonth() != monthCount && i < 52 && j > 3 && daysLeft > 7) {
          // New month
          var textMonth = createElementSvg('text', {'x': 17 * i, 'y': '-6', 'class': 'month'});
          textMonth.textContent = getNameMonth(rectDate.getMonth());
          gElementContainer.appendChild(textMonth);
          monthCount = rectDate.getMonth();
        }

        dayCount--;
        if (dayCount >= -1) {
          // Day-obj factory

          var rectElement = createElementSvg('rect', {
            'class': 'day',
            'width': '16px',
            'height': '16px',
            'data-date': formatDate(rectDate),
            'y': 17 * j
          });

          addRectElementListeners(rectElement);
          gElement.appendChild(rectElement);
        }
      }

      gElementContainer.appendChild(gElement);
    }

    var textM = createElementSvg('text', {'x': '-24', 'y': '8'});
    textM.textContent = getNameWeek(1);
    gElementContainer.appendChild(textM);
    var textW = createElementSvg('text', {'x': '-24', 'y': '46'});
    textW.textContent = getNameWeek(3);
    gElementContainer.appendChild(textW);
    var textF = createElementSvg('text', {'x': '-24', 'y': '80'});
    textF.textContent = getNameWeek(5);
    gElementContainer.appendChild(textF);
    var textS = createElementSvg('text', {'x': '-24', 'y': '114'});
    textS.textContent = getNameWeek(0);
    gElementContainer.appendChild(textS);

    svgElement.appendChild(gElementContainer);

    // Append Calendar to document;
    $_this.append(svgElement);

    fillData(massive);


    function createElementSvg(type, prop) {
      var e = document.createElementNS('http://www.w3.org/2000/svg', type);
      for (var p in prop) {
        e.setAttribute(p, prop[p]);
      }
      return e;
    }

    function addRectElementListeners(rectElement) {
      rectElement.onmouseover = function () {
        var dateString = $(this).attr('data-date').split('-');
        var date = new Date(dateString[0], dateString[1] - 1, dateString[2]);

        var tagDate = getBeautyDate(date);
        var tagTooltip = $(this).attr('data-tooltip');

        if (!tagTooltip) {
          tagTooltip = 'No activity';
        }

        $_tag.html('<b>' + tagTooltip + '</b> on ' + tagDate)
          .show()
          .css({
            'left': $(this).offset().left - $_tag.outerWidth() / 2 + 8,
            'top': $(this).offset().top - 33
          });
      };

      rectElement.onmouseleave = function () {
        $_tag.text('').hide();
      };

      rectElement.onclick = function () {
        settings.eventClick({
          date: $(this).attr('data-date'),
          count: $(this).attr('data-count') || 0
        });
      };
    }

    function fillData(massive) {
      for (var m in massive) {
        $_this.find('rect.day[data-date="' + massive[m].date + '"]')
          .attr('data-count', massive[m].value)
          .attr('data-tooltip', massive[m].tooltip);
      }
    }

    function getNameMonth(a) {
      return settings.months[a];
    }

    function getNameWeek(a) {
      return settings.weeks[a];
    }

    function getBeautyDate(a) {
      return getNameMonth(a.getMonth()) + ' ' + a.getDate() + ', ' + a.getFullYear();
    }

    function daysInMonth(d) {
      return 32 - new Date(d.getFullYear(), d.getMonth(), 32).getDate();
    }

    function diffDays(firstDate, secondDate) {
      return Math.round(Math.abs((firstDate - secondDate) / (24 * 60 * 60 * 1000)));
    }

    function formatDate(date) { // yyyy-mm-dd
      return date.getFullYear() + '-' + withLeadingZero(date.getMonth() + 1) + '-' + withLeadingZero(date.getDate());
    }

    function withLeadingZero(number) {
      return (number < 10) ? '0' + number : number;
    }
  };
})(jQuery);
