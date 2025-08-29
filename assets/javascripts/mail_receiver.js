// Mail Receiver Plugin JavaScript

function performManualImport() {
  var count = document.getElementById('import_count').value;
  if (count < 1 || count > 100) {
    alert('Bitte geben Sie eine Zahl zwischen 1 und 100 ein.');
    return;
  }
  
  if (confirm('Möchten Sie wirklich ' + count + ' Mails importieren?')) {
    // AJAX-Call für manuellen Import
    $.ajax({
      url: '/settings/plugin/mail_receiver',
      method: 'POST',
      data: {
        'settings[manual_import_count]': count,
        'action': 'manual_import'
      },
      success: function(response) {
        alert('Manueller Import erfolgreich gestartet!');
        location.reload();
      },
      error: function() {
        alert('Fehler beim manuellen Import.');
      }
    });
  }
}

function clearLog() {
  if (confirm('Sind Sie sicher, dass Sie das Mail-Log leeren möchten?')) {
    // AJAX-Call für Log leeren
    $.ajax({
      url: '/settings/plugin/mail_receiver',
      method: 'POST',
      data: {
        'action': 'clear_log'
      },
      success: function(response) {
        alert('Log wurde erfolgreich geleert!');
        location.reload();
      },
      error: function() {
        alert('Fehler beim Leeren des Logs.');
      }
    });
  }
}
