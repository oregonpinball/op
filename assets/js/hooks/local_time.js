/**
 * LocalTime Hook
 * 
 * Converts UTC datetime strings to the user's local timezone.
 * 
 * Usage in HEEx templates:
 *   <time 
 *     id="unique-id"
 *     phx-hook="LocalTime" 
 *     data-datetime={@datetime}
 *     data-format="full|date|time|relative"
 *   >
 *     <!-- Fallback content shown if JS disabled -->
 *   </time>
 * 
 * Formats:
 *   - full: "Mon, Jan 01, 2024 at 3:45 PM PST"
 *   - date: "Mon, Jan 01, 2024"
 *   - time: "3:45 PM"
 *   - relative: "2 hours ago" / "in 3 days"
 */
export default {
  mounted() {
    this.updateTime();
  },

  updated() {
    this.updateTime();
  },

  updateTime() {
    const datetimeStr = this.el.dataset.datetime;
    const format = this.el.dataset.format || "full";

    if (!datetimeStr) {
      console.warn("LocalTime hook: no data-datetime attribute found");
      return;
    }

    try {
      const datetime = new Date(datetimeStr);
      
      if (isNaN(datetime.getTime())) {
        console.warn("LocalTime hook: invalid datetime:", datetimeStr);
        return;
      }

      const formatted = this.formatDateTime(datetime, format);
      this.el.textContent = formatted;
      this.el.setAttribute("datetime", datetime.toISOString());
      this.el.setAttribute("title", datetime.toLocaleString());
    } catch (error) {
      console.error("LocalTime hook error:", error);
    }
  },

  formatDateTime(date, format) {
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    switch (format) {
      case "date":
        return date.toLocaleDateString("en-US", {
          weekday: "short",
          year: "numeric",
          month: "short",
          day: "numeric",
          timeZone: timeZone
        });

      case "time":
        return date.toLocaleTimeString("en-US", {
          hour: "numeric",
          minute: "2-digit",
          timeZone: timeZone
        });

      case "relative":
        return this.formatRelativeTime(date);

      case "full":
      default:
        const dateStr = date.toLocaleDateString("en-US", {
          weekday: "short",
          year: "numeric",
          month: "short",
          day: "numeric",
          timeZone: timeZone
        });
        const timeStr = date.toLocaleTimeString("en-US", {
          hour: "numeric",
          minute: "2-digit",
          timeZoneName: "short",
          timeZone: timeZone
        });
        return `${dateStr} at ${timeStr}`;
    }
  },

  formatRelativeTime(date) {
    const now = new Date();
    const diffMs = date - now;
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);

    const rtf = new Intl.RelativeTimeFormat("en", { numeric: "auto" });

    if (Math.abs(diffDay) >= 1) {
      return rtf.format(diffDay, "day");
    } else if (Math.abs(diffHour) >= 1) {
      return rtf.format(diffHour, "hour");
    } else if (Math.abs(diffMin) >= 1) {
      return rtf.format(diffMin, "minute");
    } else {
      return rtf.format(diffSec, "second");
    }
  }
};
