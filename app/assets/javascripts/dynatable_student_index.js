if($('#student-index-table').length > 0 ) {

  var dynatable = $('#student-index-table')
    .bind('dynatable:init', function(e, dynatable) {
      dynatable.sorts.functions["numeric"] = numeric;

      // Custom filter logic is defined here:
      dynatable.queries.functions['all-students'] = function(record) {
        return true;
      };
      dynatable.queries.functions['active-students'] = function(record) {
        return record.active == "true";
      };
      dynatable.queries.functions['leaderboard'] = function(record) {
        return record.rank.length && record.active == "true";
      };
      dynatable.queries.functions['top10'] = function(record) {
        return record.rank.length && record.active == "true" && parseInt(record.rank) <= 10;
      };
      dynatable.queries.functions['bottom10'] = function(record) {
        return record.rank.length && record.active == "true" && parseInt(record.rank) >
        $('#student-index-table').data()['bottom10Cutoff']
      };
      dynatable.queries.functions['flagged-students'] = function(record) {
        return $(record.flag).find("i").hasClass("flagged") && record.active == "true";
      };
      dynatable.queries.functions['auditors'] = function(record) {
        return !record.rank.length && record.active == "true";
      };
      dynatable.queries.functions['deactivated'] = function(record) {
        return record.active == "false";
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
        }
      }
    }).data('dynatable');

  var removeStudentIndexFilters = function() {
    dynatable.queries.remove('leaderboard');
    dynatable.queries.remove('active-students');
    dynatable.queries.remove('top10');
    dynatable.queries.remove('bottom10');
    dynatable.queries.remove('flagged-students');
    dynatable.queries.remove('auditors');
    dynatable.queries.remove('deactivated');
  }

  $('.button-table-action').click( function() {
    $(this).addClass("selected").attr("aria-pressed", "true").siblings().removeClass("selected").attr("aria-pressed", "false");
    var btnId = $(this).attr('id');
    removeStudentIndexFilters();
    dynatable.queries.add(btnId.replace('btn-',''));
    dynatable.process();
  });

  //start by hiding auditors in table since default button selected is leaderboard
  dynatable.queries.add('leaderboard');
  dynatable.process();

  $(document).ready(function() {
    var lowestRank = $('#student-index-table tbody tr').has('.graded').last().find('td:eq(1)').text();
    var bottom10Cutoff = lowestRank && parseInt(lowestRank) > 10 ? parseInt(lowestRank) - 10 : 0;
    $('#student-index-table').data('bottom10Cutoff', bottom10Cutoff);
  });
}
