import time

import gi

gi.require_version('IBus', '1.0')
from gi.repository import GLib, IBus


def pump(seconds):
    deadline = time.monotonic() + seconds
    loop = GLib.MainContext.default()
    while time.monotonic() < deadline:
        while loop.pending():
            loop.iteration(False)
        time.sleep(0.01)


IBus.init()
bus = IBus.Bus.new()
assert bus.is_connected(), 'Could not connect to the local IBus test socket'
context = bus.create_input_context('wslg-ime-smoke-test')
assert context is not None, 'Could not create a test input context'
commits = []
context.connect('commit-text', lambda _context, value: commits.append(value.get_text()))
context.set_capabilities(IBus.Capabilite.FOCUS | IBus.Capabilite.PREEDIT_TEXT)
context.focus_in()
context.set_engine('rime')
pump(1)
for char in 'nihc ':
    context.process_key_event(ord(char), 0, 0)
    pump(0.08)
pump(0.5)
context.focus_out()
print(''.join(commits))
assert ''.join(commits) == '\u4f60\u597d', 'Xiaohe did not commit the expected test text'
