import { hooks as colocatedHooks } from "phoenix-colocated/op";
import { ReactMount } from "./react/react_mount";
import { initializeDispatchListeners } from "./dispatch";

// Initialize custom dispatch listeners
initializeDispatchListeners();

(function () {
  window.storybook = {
    Hooks: { ...colocatedHooks, ReactMount },
    Params: {},
    Uploaders: {},
  };
})();
