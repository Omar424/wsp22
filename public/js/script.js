var urls = ['misc/barcelona.png', 'misc/bayern.png','misc/madrid.png','misc/chelsea.png','misc/dortmund.png','misc/city.png','misc/tottenham.png','misc/liverpool.png','misc/psg.png','misc/united.png'];
button = document.getElementById('button');

button.onclick = function() {
    interval = setInterval(function(urls) {
    var url = urls.pop();
    var a = document.createElement("a");
    a.setAttribute('href', url);
    a.setAttribute('download', '');
    a.setAttribute('target', '_blank');
    a.click();
    if (urls.length == 0) {clearInterval(interval); button.remove();}
    }, 400, urls);
}