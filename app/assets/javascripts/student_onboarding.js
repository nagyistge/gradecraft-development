//initiate slick slider for student onboarding slides
$('.student-onboarding-slides').slick({
  prevArrow: '<a class="fa fa-chevron-left previous slider-direction-button"></a>',
  nextArrow: '<a class="fa fa-chevron-right next slider-direction-button"></a>',
  adaptiveHeight: true,
  dots: true,
  infinite: false,
  responsive: [
    {
      breakpoint: 640,
      settings: {
        arrows: false
      }
    }
  ]
});

//modal for student onboarding from Scott O'Hara (https://www.smashingmagazine.com/2014/09/making-modal-windows-better-for-everyone/)
// helper function to place modal window as the first child
// of the #dashboard-timeline node
var m = document.getElementById('modal-window');
var p = document.querySelector('.student .offscreen-sidebar');

function swap () {
  p.parentNode.insertBefore(m, p);
}

if (m && p) {
  swap();

  // modal window
  (function() {

    'use strict';

    // list out the vars
    var mOverlay = getId('modal-window'),
        mOpen = getId('modal-open'),
        mClose = getId('modal-close'),
        mAction = getId('modal-action'),
        modal = getId('modal-holder'),
        allNodes = document.querySelectorAll("*"),
        modalOpen = false,
        lastFocus,
        i;

    // Let's cut down on what we need to type to get an ID
    function getId ( id ) {
      return document.getElementById(id);
    }

    // Let's open the modal
    function modalShow () {
      lastFocus = document.activeElement;
      mOverlay.setAttribute('aria-hidden', 'false');
      modalOpen = true;
      modal.setAttribute('tabindex', '0');
      modal.focus();
    }

    // binds to both the button click and the escape key to close the modal window
    // but only if modalOpen is set to true
    function modalClose ( event ) {
      if (modalOpen && ( !event.keyCode || event.keyCode === 27 ) ) {
        mOverlay.setAttribute('aria-hidden', 'true');
        modal.setAttribute('tabindex', '-1');
        modalOpen = false;
        lastFocus.focus();
      }
    }

    // Restrict focus to the modal window when it's open.
    // Tabbing will just loop through the whole modal.
    // Shift + Tab will allow backup to the top of the modal,
    // and then stop.
    function focusRestrict ( event ) {
      if ( modalOpen && !modal.contains( event.target ) ) {
        event.stopPropagation();
        modal.focus();
      }
    }

    // Close modal window by clicking on the overlay
    mOverlay.addEventListener('click', function( e ) {
      if (e.target == modal.parentNode) {
         modalClose( e );
       }
    }, false);

    // open modal by btn click/hit
    mOpen.addEventListener('click', modalShow);

    // close modal by btn click/hit
    mClose.addEventListener('click', modalClose);

    // close modal by modal action btn click/hit
    mAction.addEventListener('click', modalClose);

    // close modal by keydown, but only if modal is open
    document.addEventListener('keydown', modalClose);

    // restrict tab focus on elements only inside modal window
    for (i = 0; i < allNodes.length; i++) {
      allNodes.item(i).addEventListener('focus', focusRestrict);
    }

  })();
}
