/*
 * Ten Shadows Kris — flavor text registry
 *
 * Small, data-driven dialogue helper for the browser prototype.
 * Conditions are checked against a state object supplied by the caller.
 */

(function (root) {
  "use strict";

  const entries = Object.create(null);

  function register(id, lines) {
    if (typeof id !== "string" || !id.trim()) {
      throw new TypeError("Flavor text ID must be a non-empty string.");
    }
    if (!Array.isArray(lines) || lines.length === 0) {
      throw new TypeError("Flavor text entries must be a non-empty array.");
    }
    entries[id] = lines.map((entry) => {
      if (typeof entry === "string") {
        return { text: entry, when: () => true };
      }
      if (!entry || typeof entry.text !== "string") {
        throw new TypeError("Each flavor text entry needs a text string.");
      }
      return {
        text: entry.text,
        when: typeof entry.when === "function" ? entry.when : () => true
      };
    });
  }

  function get(id, state = {}, options = {}) {
    const candidates = (entries[id] || []).filter((entry) => {
      try {
        return entry.when(state);
      } catch (error) {
        console.warn("Flavor text condition failed:", id, error);
        return false;
      }
    });

    if (candidates.length === 0) return options.fallback || null;

    const previous = options.previous || null;
    const available = candidates.filter((entry) => entry.text !== previous);
    const pool = available.length ? available : candidates;
    const selected = pool[Math.floor(Math.random() * pool.length)];

    return selected.text;
  }

  function has(id) {
    return Object.prototype.hasOwnProperty.call(entries, id);
  }

  const api = Object.freeze({ register, get, has });
  root.FlavorText = api;

  // Confirmed opening flavor text for the Roaring Knight.
  register("roaring_knight.opening", [
    "You feel incoming dread."
  ]);

  // Base Knight battle flavor: the North and East winds.
  register("roaring_knight.battle", [
    "All the winds blow fiercely."
  ]);

  // The Odd Radio's description deliberately gives away nothing.
  register("items.odd_radio.inspect", [
    "A very, very interesting old radio. Wonder what it's for."
  ]);

  // The mysterious armor that is, inexplicably, a jar of mayonnaise.
  register("items.mayo_armor.inspect", [
    "It's mayonnaise. Somehow, it's protective."
  ]);

  // Gaster-related text can be rendered with the Wingdings-style font later.
  // Keep the source text separate from its display font/encoding.
  register("gaster.radio_hint", [
    "Very, very interesting."
  ]);
})(typeof window !== "undefined" ? window : globalThis);
