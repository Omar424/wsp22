var urls = ['misc/barcelona.png','misc/madrid.png', 'misc/bayern.png'];
button = document.getElementById('button');

button.onclick = function() {
    interval = setInterval(function(urls) {
    var url = urls.pop();
    var a = document.createElement("a");
    a.setAttribute('href', url);
    a.setAttribute('download', '');
    a.setAttribute('target', '_blank');
    a.click();
    if (urls.length == 0) {clearInterval(interval);}
    }, 400, urls);
}