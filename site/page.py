#!/usr/bin/env python3

class Page:
    def __init__(self, title = "", cookies = {}):
        self.text = "Content-Type: application/xhtml+xml; charset=utf-8\n"
        for key in cookies:
            self.text += "Set-Cookie: " + key + "=" + cookies[key] + "\n"
        self.text += "\n"
        self.text += "<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='it'>"
        self.text += "<head><meta charset='UTF-8'/>"
        self.text += "<title>" + title + "</title></head>"
        self.text += "<body>"
    def finalize(self):
        self.text += "</body></html>"
        return self.text
    def add_text(self, txt):
        self.text += txt
    def add_button(self, label, url = "", disabled = False):
        self.text += "<button type='button'"
        if url != "":
            self.text += " onclick='window.location.href = \"" + url + "\"'"
        if disabled:
            self.text += " disabled='disabled'"
        self.text += ">" + label + "</button>"
    def add_newline(self):
        self.text += "<br/>"
    def add_paragraph(self, txt):
        self.text += "<p>" + txt + "</p>"
    def add_title(self, txt):
        self.text += "<h1>" + txt + "</h1>"
    def add_form(self, url, fields, send_label = "Invia", method = "post"):
        self.text += "<form method='" + method + "' action='" + url +"'>"
        for field in fields:
            self.text += field["pn"] + ": <input type='" + field["t"] + "' name='" + field["n"] + "'"
            if "p" in field:
                self.text += " placeholder='" + field["p"] + "'"
            if field["t"] == "number":
                if "min" in field:
                    self.text += " min='" + field["min"] + "'"
            self.text += "/><br/>"
        self.text += "<input type='submit' value='" + send_label + "'/></form>"
