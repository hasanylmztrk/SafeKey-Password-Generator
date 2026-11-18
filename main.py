from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.slider import Slider
from kivy.uix.checkbox import CheckBox
from kivy.core.window import Window
from kivy.utils import platform
import random
import string

# Desktop window size, fullscreen on mobile
if platform in ('win', 'linux', 'macosx'):
    Window.size = (400, 650)

class SafeKeyApp(App):
    def build(self):
        self.title = "SafeKey"
        self.current_password = ""
        self.use_upper = True
        self.use_numbers = True
        self.use_symbols = True

        layout = BoxLayout(orientation='vertical', padding=20, spacing=12)

        layout.add_widget(Label(text="SafeKey", font_size=34, bold=True, size_hint=(1, 0.15)))
        layout.add_widget(Label(text="Secure Password Generator", font_size=15, size_hint=(1, 0.08)))

        self.password_label = Label(
            text="Your password will appear here",
            font_size=17,
            size_hint=(1, 0.18)
        )
        layout.add_widget(self.password_label)

        self.length_label = Label(text="Length: 16", font_size=16, size_hint=(1, 0.08))
        layout.add_widget(self.length_label)

        self.slider = Slider(min=8, max=32, value=16, step=1, size_hint=(1, 0.1))
        self.slider.bind(value=self.on_slider)
        layout.add_widget(self.slider)

        # Options
        layout.add_widget(self.make_option("Uppercase (ABC)", True, "upper"))
        layout.add_widget(self.make_option("Numbers (123)", True, "numbers"))
        layout.add_widget(self.make_option("Symbols (!@#)", True, "symbols"))

        btn_generate = Button(text="GENERATE PASSWORD", font_size=20, size_hint=(1, 0.15), background_color=(0.2, 0.6, 1, 1))
        btn_generate.bind(on_press=self.generate)
        layout.add_widget(btn_generate)

        self.btn_copy = Button(text="COPY", font_size=18, size_hint=(1, 0.15), background_color=(0.2, 0.8, 0.4, 1))
        self.btn_copy.bind(on_press=self.copy_pass)
        layout.add_widget(self.btn_copy)

        return layout

    def make_option(self, text, default, key):
        row = BoxLayout(orientation='horizontal', size_hint=(1, 0.08), spacing=10)
        cb = CheckBox(active=default, size_hint=(0.2, 1))
        cb.bind(active=lambda inst, val, k=key: self.set_option(k, val))
        row.add_widget(cb)
        row.add_widget(Label(text=text, font_size=15, halign='left'))
        return row

    def set_option(self, key, val):
        if key == "upper":
            self.use_upper = val
        elif key == "numbers":
            self.use_numbers = val
        elif key == "symbols":
            self.use_symbols = val

    def on_slider(self, instance, value):
        self.length_label.text = f"Length: {int(value)}"

    def generate(self, instance):
        length = int(self.slider.value)
        chars = string.ascii_lowercase
        if self.use_upper:
            chars += string.ascii_uppercase
        if self.use_numbers:
            chars += string.digits
        if self.use_symbols:
            chars += "!@#$%^&*"

        password = ''.join(random.choice(chars) for _ in range(length))
        self.current_password = password
        self.password_label.text = password
        self.btn_copy.text = "COPY"

    def copy_pass(self, instance):
        if not self.current_password:
            self.btn_copy.text = "GENERATE FIRST!"
            return
        try:
            from kivy.core.clipboard import Clipboard
            Clipboard.copy(self.current_password)
            self.btn_copy.text = "COPIED!"
        except Exception:
            self.btn_copy.text = "COPY FAILED"

if __name__ == '__main__':
    SafeKeyApp().run()
