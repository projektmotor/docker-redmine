// Observ field function

(function( $ ){

  jQuery.fn.observe_field = function(frequency, callback) {

    frequency = frequency * 100; // translate to milliseconds

    return this.each(function(){
      var $this = $(this);
      var prev = $this.val();

      var check = function() {
        if(removed()){ // if removed clear the interval and don't fire the callback
          if(ti) clearInterval(ti);
          return;
        }

        var val = $this.val();
        if(prev != val){
          prev = val;
          $this.map(callback); // invokes the callback on $this
        }
      };

      var removed = function() {
        return $this.closest('html').length == 0
      };

      var reset = function() {
        if(ti){
          clearInterval(ti);
          ti = setInterval(check, frequency);
        }
      };

      check();
      var ti = setInterval(check, frequency); // invoke check periodically

      // reset counter after user interaction
      $this.bind('keyup click mousemove', reset); //mousemove is for selects
    });

  };

})( jQuery );


function setupDeferredTabs(url) {
    $('body').on('click', '.tab-header', function(e){
        tab = $(e.target);
        $('.tab-placeholder').removeClass('active');
        name = tab.data('name');
        partial = tab.data('partial');
        placeholder = $('#tab-placeholder-' + name);
        placeholder.addClass('active');

        if (!placeholder.is('.loaded')) {
            url = url
            $.ajax(url, {
                data: {tab_name: name, partial: partial},
                complete: function(){
                    placeholder.addClass('loaded')
                    //replaces current URL with the "href" attribute of the current link
                    //(only triggered if supported by browser)
                    if ("replaceState" in window.history) {
                      window.history.replaceState(null, document.title, tab.attr('href'));
                    }
                    return undefined;
                },
                dataType: 'script'
            })
        }
        else {
            if ("replaceState" in window.history) {
                window.history.replaceState(null, document.title, tab.attr('href'));
            }
        }
    })
};


//replaces redmine default method showTab() beacuse of compatibility Redmine 3.1+
function showPeopleTab(name, url) {
  $('div#content .tab-content').hide();
  $('div.tabs a').removeClass('selected');
  $('#tab-content-' + name).show();
  $('#tab-' + name).addClass('selected');
  if ("replaceState" in window.history) {
    window.history.replaceState(null, document.title, url);
  }
  return false;
}

//show modal div for announcements
function showAnnouncement(url){
  $.ajax({
      url: url,
      type: 'post',
      data:{
        people_announcement:{
          description: $("#announcement_description").val(),
          kind: $("#people_announcement_kind").val()
        }
      },
      success: function(data, status, xhr) {
        $("#announcement-show").html(data);
        showModal('announcement-show', '50%');
      }
    });
}

function updateTab(name, url, data) {
  $.ajax({
    url: url,
    dataType: 'script',
    data: data,
    success: function () {
      if ("replaceState" in window.history) {
        window.history.replaceState(null, document.title, $('#tab-' + name).attr('href'));
      }
    }
  });
};

function addEditableBarsOnClickListener() {
  $('.tooltip.editable').on('click', function () {
    $.ajax(this.getAttribute('edit_url'))
  });
};
