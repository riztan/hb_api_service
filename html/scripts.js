const app = document.getElementById('root');

const logo = document.createElement('img');
logo.src = 'logo.png';

const container = document.createElement('div');
container.setAttribute('class', 'container');

app.appendChild(logo);
app.appendChild(container);

var request = new XMLHttpRequest();
//request.open('GET', 'https://ghibliapi.herokuapp.com/films', true);
//request.open('POST', 'https://riztan.ddns.net:8001/tpy?login=riztang&pass=01020304', true);
request.open('POST', 'https://localhost:8001/tpy?login=riztang&pass=01020304', true);
//request.withCredentials = false ;
request.onload = function () {

  // Begin accessing JSON data here
  var data = JSON.parse(this.response);
  if (request.status >=200 && request.status < 400){
/*	  
     data.forEach( item => {
        const card = document.createElement('div');
	card.setAttribute('class', 'card');

        const h1 = document.createElement('h1');
        h1.textContent = CUSERNAME;	

     });
*/
	var user = data.content.user_data;

        const card = document.createElement('div');
        card.setAttribute('class', 'card');

        const h1 = document.createElement('div');
        h1.textContent = "Cadena de Identificación: "+data.content.session_id;

        container.appendChild(card);
        card.appendChild(h1);

        const h2 = document.createElement('div');
        h2.textContent = "Nombre: "+user.firstname;
        card.appendChild(h2);

        const h3 = document.createElement('div');
        h3.textContent = "Apellido: "+user.lastname;
        card.appendChild(h3);

        const h4 = document.createElement('div');
        h4.textContent = "Nombre corto: "+user.shortname;
        card.appendChild(h4);

        const h5 = document.createElement('div');
        h5.textContent = "Correo electrónico: "+user.email;
        card.appendChild(h5);

  }else{
    const errorMessage = document.createElement('marquee');
    errorMessage.textContent = `oh oh, no está funcionando!`;
    app.appendChild(errorMessage);     
  }
  console.log("fin");
  /*
  if (request.status >= 200 && request.status < 400) {
    //data.forEach(movie => {
      const card = document.createElement('div');
      card.setAttribute('class', 'card');

      const h1 = document.createElement('h1');
      h1.textContent = CNAME;

      const p = document.createElement('p');
      //movie.description = movie.description.substring(0, 300);
      p.textContent = cshortname; //`${movie.description}...`;

      container.appendChild(card);
      card.appendChild(h1);
      card.appendChild(p);
    //});
  } else {
    const errorMessage = document.createElement('marquee');
    errorMessage.textContent = `oh oh, no está funcionando!`;
    app.appendChild(errorMessage);
  }
  */
}

request.send();
