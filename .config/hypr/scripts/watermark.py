#!/usr/bin/env python3
# Persistent decorative corner watermark (Ayana / CachyOS), always on top of
# every window via the Wayland layer-shell overlay layer. Click-through (empty
# input region) so it never intercepts clicks meant for windows underneath.
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, Gtk4LayerShell, Gdk, GLib

CSS = b"""
window {
    background: transparent;
}
#watermark {
    font-family: "IBM Plex Sans Condensed", sans-serif;
    color: rgba(255, 255, 255, 0.20);
    font-weight: 700;
}
#line1 {
    font-size: 33.75px;
    letter-spacing: 0.02em;
}
#line2 {
    font-size: 24.75px;
    letter-spacing: 0.12em;
}
"""


def on_activate(app):
    window = Gtk.ApplicationWindow(application=app)
    Gtk4LayerShell.init_for_window(window)
    Gtk4LayerShell.set_layer(window, Gtk4LayerShell.Layer.OVERLAY)
    Gtk4LayerShell.set_anchor(window, Gtk4LayerShell.Edge.BOTTOM, True)
    Gtk4LayerShell.set_anchor(window, Gtk4LayerShell.Edge.RIGHT, True)
    Gtk4LayerShell.set_margin(window, Gtk4LayerShell.Edge.BOTTOM, 24)
    Gtk4LayerShell.set_margin(window, Gtk4LayerShell.Edge.RIGHT, 32)
    Gtk4LayerShell.set_exclusive_zone(window, -1)
    Gtk4LayerShell.set_keyboard_mode(window, Gtk4LayerShell.KeyboardMode.NONE)

    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, halign=Gtk.Align.START)
    box.set_name("watermark")
    line1 = Gtk.Label(label="Ayana", halign=Gtk.Align.START)
    line1.set_name("line1")
    line2 = Gtk.Label(label="CACHYOS", halign=Gtk.Align.START)
    line2.set_name("line2")
    box.append(line1)
    box.append(line2)
    window.set_child(box)

    # Click-through: empty input region means the surface never receives pointer events.
    window.connect("realize", lambda w: w.get_surface().set_input_region(
        __import__("cairo").Region()
    ))

    window.present()


app = Gtk.Application(application_id="dev.ayana.watermark")
provider = Gtk.CssProvider()
provider.load_from_data(CSS)
Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)
app.connect("activate", on_activate)
app.run(None)
