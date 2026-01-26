export default {
  mounted() {
    this.$nav = document.getElementById("nav-op");
    this.$hero = document.getElementById("landing-hero");
    
    if (!this.$nav || !this.$hero) {
      console.warn("BackgroundColorWatcher: nav-op or landing-hero element not found");
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

    // Listen to scroll events
    window.addEventListener("scroll", this.handleScroll);
    this.handleScroll();
  },

  destroyed() {
    // Clean up the event listener when the hook is destroyed
    if (this.handleScroll) {
      window.removeEventListener("scroll", this.handleScroll);
    }
  }
};
