import PropTypes from 'prop-types';
import React from 'react';

export default class GradeCraft extends React.Component {
  static propTypes = {
    id: PropTypes.string.isRequired, // this is passed from the Rails view
  };

  /**
   * @param props - Comes from your rails view.
   * @param _railsContext - Comes from React on Rails
   */
  constructor(props, _railsContext) {
    super(props);

    // How to set initial state in ES6 class syntax
    // https://facebook.github.io/react/docs/reusable-components.html#es6-classes
    this.state = { id: this.props.id };
  }

  updateName = (id) => {
    this.setState({ id });
  };

  render() {
    return (
      <div>
        <h3>
          Assignment id: {this.state.id}
        </h3>
      </div>
    );
  }
}
