// ______ _                 _       _
// |  _  (_)               | |     | |
// | | | |_ ___ _ __   __ _| |_ ___| |__
// | | | | / __| '_ \ / _` | __/ __| '_ \
// | |/ /| \__ \ |_) | (_| | || (__| | | |
// |___/ |_|___/ .__/ \__,_|\__\___|_| |_|
//             | |
//             |_|
// Listeners from `JS.dispatch/2` calls in Elixir components

/**
 * Initialize custom event listeners for Phoenix LiveView JS.dispatch/2 calls
 */
export function initializeDispatchListeners() {
  window.addEventListener("op:toggle", (e) => {
    const $sheet = e.target;

    // Find and show children with data-sheet-bg or data-sheet-content
    const $sheetBg = $sheet.querySelector("[data-sheet-bg]")
    const $sheetContent = $sheet.querySelector("[data-sheet-content]")
    console.debug("op:toggle received", { $sheet, $sheetBg, $sheetContent })

    if ($sheet.classList.contains("hidden")) {
      $sheet.classList.remove("hidden")
      $sheetContent.classList.remove("hidden")
      $sheetContent.classList.add("animate-slide-in-right")
      document.body.classList.add("overflow-hidden")
    } else {
      $sheetContent.classList.remove("animate-slide-in-right")
      $sheetContent.classList.add("animate-slide-out-right")
      $sheetContent.addEventListener(
        "animationend",
        () => {
          $sheet.classList.add("hidden")
          $sheetContent.classList.add("hidden")
          $sheetContent.classList.remove("animate-slide-out-right")
          document.body.classList.remove("overflow-hidden")
        },
        { once: true }
      )
    }
  });
}
