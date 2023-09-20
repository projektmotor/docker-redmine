function setAgileSprintEndDate(){
  var start_date = new Date($("#agile_sprint_start_date").val());
  var end_date = new Date(start_date);
  var duration = this.value;
  if (start_date && duration >= 1) {
    end_date.setDate(start_date.getDate() + duration * 7);
    $("#agile_sprint_end_date").val(end_date.getFullYear() + '-' + ('0' + (end_date.getMonth() + 1)).slice(-2) + '-' + ('0' + end_date.getDate()).slice(-2));
    $("#agile_sprint_duration").val(null);
  }
}

$(document).ready(function(){
  $('#content').on('change', '#agile_sprint_duration', setAgileSprintEndDate);
});
