from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
import random, string

class SafeKeyApp(App):
    def build(self):
        self.layout = BoxLayout(orientation='vertical', padding=30, spacing=20)
        self.lbl = Label(text='SafeKey\nŞifren burada çıkacak', font_size=24)
        btn = Button(text='ŞİFRE ÜRET', font_size=22, size_hint_y=None, height=70)
        btn.bind(on_press=self.uret)
        self.layout.add_widget(self.lbl)
        self.layout.add_widget(btn)
        return self.layout

    def uret(self, x):
        harfler = string.ascii_letters + string.digits + "!@#$"
        sifre = ''.join(random.choice(harfler) for _ in range(16))
        self.lbl.text = sifre

SafeKeyApp().run()
