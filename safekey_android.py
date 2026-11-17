from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
import random, string

class SafekeyApp(App):
    def build(self):
        self.layout = BoxLayout(orientation='vertical', padding=20, spacing=20)
        self.label = Label(text='Şifren burada çıkacak', font_size=22)
        btn = Button(text='ŞİFRE ÜRET', font_size=28, size_hint=(1, 0.4))
        btn.bind(on_press=self.uret)
        self.layout.add_widget(self.label)
        self.layout.add_widget(btn)
        return self.layout

    def uret(self, x):
        harfler = string.ascii_letters + string.digits + "!@#$"
        sifre = ''.join(random.choice(harfler) for i in range(16))
        self.label.text = sifre

SafekeyApp().run()
