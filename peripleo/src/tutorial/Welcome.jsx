import React, { useState } from 'react';
import ReactDOM from 'react-dom';
import { IoMdCheckboxOutline, IoMdSquareOutline } from 'react-icons/io';

import { BEEN_HERE_TOKEN } from './Tutorial';

const Welcome = props => {

  const [ checked, setChecked ] = useState(false);

  const toggleDoNotShow = () => {
    if (checked)
      localStorage.removeItem(BEEN_HERE_TOKEN);
    else 
      localStorage.setItem(BEEN_HERE_TOKEN, true);
    
    setChecked(!checked);
  }

  return ReactDOM.createPortal(
    <div className="p6o-welcome-wrapper">
      <div className="p6o-welcome">
        <h1>Welcome!</h1>

        <p>
          Welcome to this instance of Peripleo, originally developed for 
          the <strong>Locating a National Collection</strong> project. 
          This tool shows Historic England's Heritage at Risk Data set.
          Take the tour to learn about the main user interface elements.
        </p>
        
        <div className="p6o-welcome-buttons">
          <label>
            <input 
              type="checkbox" 
              checked={checked} 
              onChange={toggleDoNotShow} />

            { checked ? <IoMdCheckboxOutline /> : <IoMdSquareOutline /> }

            <span>Don't ask again</span>
          </label>
          
          <button 
            className="p6o-no-thanks"
            onClick={props.onNoThanks}>
            No thank you
          </button>

          <button 
            className="p6o-take-tour"
            onClick={props.onTakeTour}>
            Take the tour
          </button>
        </div>
      </div>
    </div>,

    document.body
  );

}

export default Welcome;