/* Weird Route: Ice — route-state foundation.
 * Tracks choices without forcing route activation until story conditions are defined.
 */
(function (global) {
  "use strict";

  const state = {
    status: "dormant", // dormant | noticed | active | locked
    iceActions: 0,
    pressureActions: 0,
    mercyActions: 0,
    routeFlags: Object.create(null),
    history: []
  };

  function record(type, detail) {
    state.history.push({ type, detail: detail || "", at: Date.now() });
    if (state.history.length > 100) state.history.shift();
    return snapshot();
  }

  function snapshot() {
    return {
      status: state.status,
      iceActions: state.iceActions,
      pressureActions: state.pressureActions,
      mercyActions: state.mercyActions,
      routeFlags: { ...state.routeFlags },
      history: state.history.slice()
    };
  }

  const WeirdRouteIce = {
    get state() { return snapshot(); },

    recordIceAction(detail) {
      if (state.status === "locked") return snapshot();
      state.iceActions++;
      record("ice", detail);
      if (state.status === "dormant") state.status = "noticed";
      return snapshot();
    },

    recordPressure(detail) {
      if (state.status === "locked") return snapshot();
      state.pressureActions++;
      return record("pressure", detail);
    },

    recordMercy(detail) {
      if (state.status === "locked") return snapshot();
      state.mercyActions++;
      return record("mercy", detail);
    },

    setFlag(name, value = true) {
      if (!name || typeof name !== "string") throw new TypeError("Route flag needs a name.");
      state.routeFlags[name] = value;
      return record("flag", name + "=" + String(value));
    },

    hasFlag(name) {
      return !!state.routeFlags[name];
    },

    activate(reason) {
      if (state.status === "locked") return false;
      state.status = "active";
      record("activated", reason || "story event");
      return true;
    },

    lock(reason) {
      state.status = "locked";
      record("locked", reason || "story event");
    },

    reset() {
      state.status = "dormant";
      state.iceActions = 0;
      state.pressureActions = 0;
      state.mercyActions = 0;
      state.routeFlags = Object.create(null);
      state.history = [];
      return snapshot();
    }
  };

  global.WeirdRouteIce = WeirdRouteIce;
})(window);
