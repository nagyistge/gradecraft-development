// Filter my planner items in "due this week" module
$('#my-planner').click(function() {
  $('#my-planner').attr('aria-pressed', true).addClass("selected");
  $('#course-planner').attr('aria-pressed', false).removeClass("selected");
  $('.my-planner-list').show().attr('aria-hidden', 'false');
  $('.course-planner-list').hide().attr('aria-hidden', 'true');
});

$('#course-planner').click(function() {
  $('#course-planner').attr('aria-pressed', true).addClass("selected");
  $('#my-planner').attr('aria-pressed', false).removeClass("selected");
  $('.course-planner-list').show().attr('aria-hidden', 'false');
  $('.my-planner-list').hide().attr('aria-hidden', 'true');
});

//Find event with closest date
if($("#dashboard-timeline").length) {
  $.ajax({
    type: 'GET',
    url: 'api/timeline_events',
    dataType: 'json',
    contentType: 'application/json',
    success: function (json) {
      setInitialEventSlide(json);
    }
 });
}

function setInitialEventSlide(eventJson){
  var events = eventJson.timeline.date;
  var todaysDate = new Date();
  var startIndex = null;
  var noUpcomingEventsSlide = '<div class="event-slide last-slide"><div class="empty-state-wrapper large"><img src="/images/no-upcoming-events.svg" class="empty-state-graphic" alt="No upcoming events"></div></div>'

  for (var i = 0; i < events.length; i++) {
    var eventEndDate = new Date(events[i].endDate);
    if (eventEndDate >= todaysDate) {
      startIndex = i;
      break;
    }
  }

  if (startIndex === null) {
    $('.slide-container').append(noUpcomingEventsSlide);
    startIndex = events.length;
  }

  $('#events-loading-spinner').hide();
  initSlickSlider(startIndex);
}

// Initialize slick slider for course events
function initSlickSlider(startIndex) {
  $('.slide-container').slick({
    prevArrow: '<a class="fa fa-chevron-left previous slider-direction-button" aria-label="View previous course event"></a>',
    nextArrow: '<a class="fa fa-chevron-right next slider-direction-button" aria-label="View next course event"></a>',
    initialSlide: startIndex,
    adaptiveHeight: true,
    infinite: false
  });

  $('.slide-header').each(function () {
      var $slide = $(this).parent();
      if ($slide.attr('aria-describedby') != undefined) { // ignore extra/cloned slides
          $(this).attr('id', $slide.attr('aria-describedby'));
      }
  });
}



// Open dropdown menus on click and hide on body click
$(document).on('click', function(event) {
  var $this = $(event.target);
  var $dropdownContent = $('.dropdown-content');

  if ($this.parent().hasClass('dropdown')) {
    var $thisDropdownContent = $this.siblings('.dropdown-content');
    $dropdownContent.not($thisDropdownContent).hide();
    $thisDropdownContent.toggle();
  } else if (!$this.closest('.dropdown').length) {
    $dropdownContent.hide();
  }
});
