import React from 'react';
import { createRoot } from 'react-dom/client';
import PageEditor from '../react/components/PageEditor';

export default {
  mounted() {
    // Get the initial content from the element's data attribute or textarea
    const html = this.el.dataset.html || this.el.value || '';
    const key = this.el.dataset.key || 'html';

    // Create a container for the React editor
    const editorContainer = document.createElement("div");
    editorContainer.className = "react-page-editor";
    
    // If the element is a textarea, hide it and insert the editor after it
    if (this.el.tagName === 'TEXTAREA') {
      this.el.style.display = "none";
      this.el.parentNode.insertBefore(editorContainer, this.el.nextSibling);
    } else {
      // Otherwise, render the editor inside the element
      this.el.appendChild(editorContainer);
    }

    // Create React root and render the PageEditor component
    this.root = createRoot(editorContainer);
    this.root.render(
      <PageEditor 
        html={html}
        onUpdate={(content) => {
          // Update the textarea value if it exists
          this.pushEvent("fir:update", {html: content, key: key})        }}
      />
    );
  },

  updated() {
    // React handles updates internally
    // If needed, you could re-render with new props here
  },

  destroyed() {
    // Clean up the React root when the hook is destroyed
    if (this.root) {
      this.root.unmount();
    }
  }
};
