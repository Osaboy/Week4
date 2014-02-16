$(document).ready(function() {
  $('#player_color').click(function() {
    $('#player_area').css('background-color','yellow');
    return false;
  });

  $(document).on('click','#hit_form input',function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/hit'
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });

});

