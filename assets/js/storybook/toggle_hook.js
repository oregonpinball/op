export const ToggleHook = {
  mounted() {
    this.handleToggle = (e) => {
      const $sheet = e.target;

      // Find and show children with data-sheet-bg or data-sheet-content
      const $sheetBg = $sheet.querySelector("[data-sheet-bg]");
      const $sheetContent = $sheet.querySelector("[data-sheet-content]");
      console.debug("op:toggle received", { $sheet, $sheetBg, $sheetContent });

      if ($sheet.classList.contains("hidden")) {
        $sheet.classList.remove("hidden");
        $sheetContent.classList.remove("hidden");
        $sheetContent.classList.add("animate-slide-in-right");
        document.body.classList.add("overflow-hidden");
      } else {
        $sheetContent.classList.remove("animate-slide-in-right");
        $sheetContent.classList.add("animate-slide-out-right");
        $sheetContent.addEventListener(
          "animationend",
          () => {
            $sheet.classList.add("hidden");
            $sheetContent.classList.add("hidden");
            $sheetContent.classList.remove("animate-slide-out-right");
            document.body.classList.remove("overflow-hidden");
          },
          { once: true }
        );
      }
    };

    window.addEventListener("op:toggle", this.handleToggle);
  },

  destroyed() {
    window.removeEventListener("op:toggle", this.handleToggle);
  }
};
