if($('#course-index-table').length > 0 ) {

  var dynatable = $('#course-index-table')
    .bind('dynatable:init', function(e, dynatable) {
      dynatable.sorts.functions["numeric"] = numeric;
      dynatable.sorts.functions["date"] = date;

      // Custom filter logic is defined here:
      dynatable.queries.functions['all-courses'] = function(record) {
        return true;
      };
      dynatable.queries.functions['active'] = function(record) {
        return parseInt(record.active) == 1
      };
      dynatable.queries.functions['inactive'] = function(record) {
        return parseInt(record.active) == 0
      };
      dynatable.queries.functions['published'] = function(record) {
        return parseInt(record.published) == 1
      };
      dynatable.queries.functions['unpublished'] = function(record) {
        return parseInt(record.published) == 0
      };
      dynatable.queries.functions['badges'] = function(record) {
        return parseInt(record.badges) == 1
      };
      dynatable.queries.functions['sections'] = function(record) {
        return parseInt(record.sections) == 1
      };
      dynatable.queries.functions['paid'] = function(record) {
        return parseInt(record.paid) == 1
      };
      dynatable.queries.functions['unpaid'] = function(record) {
        return parseInt(record.paid) == 0
      };
    })
    .dynatable({
      features: {
        paginate: false,
        recordCount: false,
        sorting: false,
        search: true
      },
      dataset: {
        sortTypes: {
          score: 'numeric',
          rank: 'numeric',
          created: 'date'
        }
      }
    }).data('dynatable');

  var removeCourseIndexFilters = function() {
    dynatable.queries.remove('active');
    dynatable.queries.remove('inactive');
    dynatable.queries.remove('published');
    dynatable.queries.remove('unpublished');
    dynatable.queries.remove('badges');
    dynatable.queries.remove('sections');
    dynatable.queries.remove('paid');
    dynatable.queries.remove('unpaid');
  }

  $('.button-table-action').click( function() {
    $(this).addClass("selected").attr("aria-pressed", "true").siblings().removeClass("selected").attr("aria-pressed", "false");
    var btnId = $(this).attr('id');
    removeCourseIndexFilters();
    dynatable.queries.add(btnId.replace('btn-',''));
    dynatable.process();
  });

  //start by hiding inactive courses in table since default button selected is active
  dynatable.queries.add('active');
  dynatable.process();

  $(document).ready(function() {
    var lowestRank = $('#course-index-table tbody tr').has('.graded').last().find('td:eq(1)').text();
    var bottom10Cutoff = lowestRank && parseInt(lowestRank) > 10 ? parseInt(lowestRank) - 10 : 0;
    $('#course-index-table').data('bottom10Cutoff', bottom10Cutoff);
  });
}
