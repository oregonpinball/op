import React from 'react';
import { createRoot } from 'react-dom/client';
import HelloWorld from './components/HelloWorld';

// Map of component names to actual components
const components = {
  HelloWorld
};

// Function to mount React components
export function mountReactComponents() {
  document.querySelectorAll('[data-react-component]').forEach(el => {
    const componentName = el.getAttribute('data-react-component');
    const Component = components[componentName];
    
    if (Component) {
      const root = createRoot(el);
      root.render(<Component />);
    } else {
      console.error(`React component "${componentName}" not found`);
    }
  });
}

// LiveView hook to mount React components
export const ReactMount = {
  mounted() {
    mountReactComponents();
  },
  updated() {
    mountReactComponents();
  }
};
