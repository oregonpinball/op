const Clipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.clipboardText;
      if (!text) return;

      navigator.clipboard.writeText(text).then(() => {
        const label = this.el.querySelector("[data-label]");
        if (label) {
          const original = label.textContent;
          label.textContent = "Copied!";
          setTimeout(() => {
            label.textContent = original;
          }, 2000);
        }
      });
    });
  },
};

export default Clipboard;
