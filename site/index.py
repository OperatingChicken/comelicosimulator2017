#!/usr/bin/env python3

import cgi
import cgitb
import db
import session
import page
import os
import sys
import hashlib

cgitb.enable()
def exception_handler(a, b, c):
    print("Content-Type: text/html")
    print()
    cgitb.handler((a, b, c))
sys.excepthook = exception_handler

database = db.DB("game", "comsimgame17", "game", "game", "eip.ovh", True)

cookie = {}
if "HTTP_COOKIE" in os.environ:
    cookies = os.environ["HTTP_COOKIE"]
    cookies = cookies.split("; ")
    for c in cookies:
        c = c.split("=")
        cookie[c[0]] = c[1]
form = cgi.FieldStorage()

if "magic" in cookie:
    user_hash = cookie["magic"]
    p = page.Page("Comelico Simulator 2017")
else:
    user_hash = session.generate_random_id()
    p = page.Page("Comelico Simulator 2017", {"magic":  user_hash})

sess = session.Session(user_hash, database)

index = form.getfirst("page", "index")
if "logged" not in sess.data and index != "register":
    index = "login"

if "logged" in sess.data and sess.data["logged"] and index == "login":
    index = "index"

def redirect(where):
    global sess
    global database
    sess.update()
    database.finalize()
    print("Location: " + where)
    print()
    sys.exit(0)

if index == "login":
    if ("email" in form) and ("password" in form):
        email = form.getfirst("email")
        password = hashlib.sha512(form.getfirst("password").encode()).hexdigest()
        r = database.query("SELECT id, nome FROM utente WHERE email = %s AND pw = %s", (email, password))
        assert(len(r) <= 1)
        if len(r) == 0:
            redirect("index.py?page=login&err=1")
        else:
            sess.data["logged"] = True
            sess.data["username"] = r[0][1]
            sess.data["id"] = r[0][0]
            redirect("index.py")
    else:
        p.add_title("Login")
        p.add_form("index.py?page=login", [{"pn": "E-Mail", "n": "email", "t": "text"},
                                           {"pn": "Password", "n": "password", "t": "password"}], "Login")
        err = form.getfirst("err")
        if err == "1":
            p.add_paragraph("I dati di login inseriti sono errati!")
        p.add_button("Clicca qui per registrarti!", "index.py?page=register")
elif index == "register":
    if ("email" in form) and ("password" in form) and ("username" in form):
        if len(database.query("SELECT email FROM utente WHERE email = %s", (form.getfirst("email"),))) > 0:
            redirect("index.py?page=register&err=1")
        database.query("INSERT INTO utente(email, pw, nome) VALUES(%s, %s, %s)", (form.getfirst("email"), hashlib.sha512(form.getfirst("password").encode()).hexdigest(), form.getfirst("username")))
        redirect("index.py?page=login")
    else:
        p.add_title("Registrazione")
        p.add_form("index.py?page=register", [{"pn": "*E-Mail", "n": "email", "t": "email"},
                                              {"pn": "*Password", "n": "password", "t": "password"},
                                              {"pn": "Username", "n": "username", "t": "text"}], "Registrati")
        err = form.getfirst("err")
        if err == "1":
            p.add_paragraph("E-Mail già esistente!")
elif index == "index":
    players = database.query("SELECT id, nome, descr, morto FROM personaggio WHERE creato_da = %s", (sess.data["id"],))
    if len(players) == 0:
        redirect("index.py?page=create")
    p.add_title("Personaggi")
    for pl in players:
        p.add_button("Gioca", "index.py?page=play&amp;play=" + str(pl[0]), pl[3])
        p.add_text(" " + pl[1] + ": " + pl[2])
        p.add_newline()
    p.add_button("Crea un nuovo personaggio!", "index.py?page=create")
elif index == "create":
    if ("name" in form) and ("desc" in form) and ("FOR" in form) and ("INT" in form) and ("AGI" in form) and ("COS" in form):
        database.call_function("crea_personaggio", (form.getfirst("name"), form.getfirst("desc"), int(form.getfirst("FOR")), int(form.getfirst("INT")), int(form.getfirst("AGI")), int(form.getfirst("COS")), sess.data["id"]))
        redirect("index.py?page=index")
    else:
        database.call_function("tira_dadi_attr", (sess.data["id"],))
        dadi = database.query("SELECT roll1, roll2, roll3, roll4, roll5 FROM lancio_dadi_attr WHERE utente = %s", (sess.data["id"],))
        assert(len(dadi) == 1)
        p.add_title("Creazione personaggio")
        for i in range(5):
            p.add_paragraph("Dado " + str(i) + ": " + str(dadi[0][i]))
        p.add_newline()
        p.add_form("index.py?page=create", [{"pn": "*Nome", "n": "name", "t": "text"},
                                            {"pn": "Descrizione", "n": "desc", "t": "text"},
                                            {"pn": "Indice FORZA", "n": "FOR", "t": "number"},
                                            {"pn": "Indice INTELLIGENZA", "n": "INT", "t": "number"},
                                            {"pn": "Indice AGILITA", "n": "AGI", "t": "number"},
                                            {"pn": "Indice COSTITUZIONE", "n": "COS", "t": "number"}], "Crea")
else:
    p.add_paragraph("Errore!")
    p.add_text("<button type='button' onclick='window.history.back();'>Vai indietro!</button>")

sess.update()
database.finalize()
print(p.finalize())
