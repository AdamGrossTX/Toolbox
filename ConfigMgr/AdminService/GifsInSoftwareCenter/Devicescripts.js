const app = document.getElementById('root');

const container = document.createElement('div');
container.setAttribute('class', 'container');

app.appendChild(container);

var data = null;
var request = new XMLHttpRequest();
request.open('GET', 'https://cm01.asd.net/AdminService/wmi/SMS_R_System', true);

request.addEventListener("readystatechange", function () {
  if (this.readyState === 4) {
    console.log(this.responseText);
  }
});

request.onload = function () {

  // Begin accessing JSON data here
  var data = JSON.parse(this.response).value;
  //if (request.status >= 200 && request.status < 400) {
    data.forEach(function(system) {
      const card = document.createElement('div');
      card.setAttribute('class', 'card');

      const h1 = document.createElement('h1');
      h1.textContent = system.Name;

      const p = document.createElement('p');
      p.textContent = system.DistinguishedName;

      container.appendChild(card);
      card.appendChild(h1);
      card.appendChild(p);
    }
    );
  //} else {
    const errorMessage = document.createElement('marquee');
    errorMessage.textContent = "Gah, it's not working!";
    app.appendChild(errorMessage);
  //}
}

request.send();