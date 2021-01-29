const app = document.getElementById('root');

const container = document.createElement('div');
container.setAttribute('class', 'container');

app.appendChild(container);

var data = null;
var request = new XMLHttpRequest();
request.open('GET', '/AdminService/wmi/SMS_ApplicationLatest', true);
request.addEventListener("readystatechange", function (callback) {
  if (this.readyState === 4) {
    console.log(this.responseText);
  }
});
request.onload = 
function () {

  // Begin accessing JSON data here
  var data = JSON.parse(this.response).value;
  if (request.status >= 200 && request.status < 400) {
    data.forEach(function(application) {
      const card = document.createElement('div');
      card.setAttribute('class', 'card');

      const h1 = document.createElement('h1');
      h1.textContent = application.Manufacturer + ' ' + application.LocalizedDisplayName;

      card.onclick = function openTool(){
        GetComputerClientGUID(application);
      }

      const logo = document.createElement('img');
      logo.src = application.LocalizedDescription;
      
      container.appendChild(card);
      card.appendChild(h1);
      card.appendChild(logo);
      //card.appendChild(p);
    }
    );
    
  } else {
    const errorMessage = document.createElement('marquee');
    errorMessage.textContent = "Gah, it's not working!";
    app.appendChild(errorMessage);
  }
}

request.send();

//Page.Request.UserHostName

function OnApplicationClick(application,clientGUID) {
  const Http = new XMLHttpRequest();
  const url='/AdminService/wmi/SMS_ApplicationRequest.CreateApprovedRequest';
  Http.open("POST", url);
  Http.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  Http.send(JSON.stringify(
    {
      "ClientGUID":  clientGUID,
      "ApplicationId":  application.ModelName,
      "AutoInstall":  true,
      "Username":  null,
      "Comments":  "This is a test from the AdminService"
  }
  ));

  window.location = 'softwarecenter:SoftwareID=' + application.ModelName;
}

function GetComputerClientGUID(application) {
  var deviceName = document.getElementById("ComputerName").value
  var data = null;
  var request = new XMLHttpRequest();
  request.open('GET', '/AdminService/wmi/SMS_R_System?$filter=NetbiosName%20eq%20%27'+ deviceName +'%27', true);
  request.addEventListener("readystatechange", function () {
    if (this.readyState === 4) {
      console.log(this.responseText);
    }
  });
  request.onload = 
  function () {
    // Begin accessing JSON data here
    var data = JSON.parse(this.response).value;
    if (request.status >= 200 && request.status < 400) {
      var clientGUID = data[0].SMSUniqueIdentifier;

      OnApplicationClick(application,clientGUID);

    } else {
      const errorMessage = document.createElement('marquee');
      errorMessage.textContent = "Gah, it's not working!";
      app.appendChild(errorMessage);
    }
  }
  request.send();
}