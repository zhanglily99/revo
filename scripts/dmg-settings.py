"""Finder layout for Revo's drag-to-install disk image."""
from pathlib import Path

# The packaging script runs dmgbuild from the repository root.
root = Path.cwd()
app = root / 'build' / 'Revo.app'
format = 'UDZO'
compression_level = 9
filesystem = 'HFS+'
files = [str(app)]
symlinks = {'Applications': '/Applications'}
badge_icon = str(app / 'Contents' / 'Resources' / 'Revo.icns')
background = str(root / 'build' / 'installer-background.png')
window_rect = ((240, 160), (640, 420))
default_view = 'icon-view'
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
icon_size = 112
text_size = 14
icon_locations = {'Revo.app': (170, 210), 'Applications': (470, 210)}
