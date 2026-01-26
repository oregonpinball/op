export default {
  mounted() {
    this.$nav = document.getElementById("nav-op");
    this.$hero = document.getElementById("landing-hero");
    this.$scrollContainer = document.querySelector(".overflow-y-auto.h-screen");

    if (!this.$nav || !this.$hero || !this.$scrollContainer) {
      console.warn("BackgroundColorWatcher: nav-op, landing-hero, or overflow-y-auto element not found");
      return;
    }

    this.handleScroll = () => {
      const heroRect = this.$hero.getBoundingClientRect();
      const navRect = this.$nav.getBoundingClientRect();
      
      // Check if nav has scrolled past the hero element
      // The hero is "past" when its bottom edge goes above the nav's top edge
      if (heroRect.bottom - 100 < navRect.top) {
        this.$nav.classList.add("bg-green-950");
      } else {
        this.$nav.classList.remove("bg-green-950");
      }
    };

    // Listen to scroll events on the overflow container
    this.$scrollContainer.addEventListener("scroll", this.handleScroll);
    this.handleScroll();
  },

  destroyed() {
    // Clean up the event listener when the hook is destroyed
    if (this.handleScroll && this.$scrollContainer) {
      this.$scrollContainer.removeEventListener("scroll", this.handleScroll);
    }
  }
};
