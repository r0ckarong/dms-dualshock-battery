# TODO

## Next Session: Controller Popout + Visibility Selection

1. Add a popout panel in the widget that lists all detected controllers.
2. Show each controller with:
   - Display label (battery + status)
   - MAC address
   - Controller type (DualShock 4 / DualSense)
3. Add per-controller visibility toggles in the popout.
4. Persist visibility preferences in plugin data (keyed by MAC).
5. Apply visibility filtering to the existing widget display list.
6. Define behavior for edge cases:
   - New controller appears with no saved preference (default visible).
   - Saved controller is not currently connected.
   - MAC format normalization for stable matching.
7. Ensure horizontal and vertical widget modes use the same filtered source.
8. Keep the implementation runtime-safe (no dynamic object creation tricks that previously caused parser/runtime instability).
9. Add a debug mode note in UI/log text that reports visible vs hidden controller counts.
10. Update README with:
   - How to use the popout selector
   - How controller visibility persistence works

## Follow-up Ideas

- Add a quick "Show all" / "Hide all" action in the popout.
- Add sorting options (battery descending, connection status, MAC).
- Optional search filter in the popout for many paired controllers.
