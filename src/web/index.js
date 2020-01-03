import './style.css';

function component() {
  const element = document.createElement('div');
  element.classList.add('hello');
  element.innerHTML = 'Hello webpack!';

  return element;
}

document.body.appendChild(component());
